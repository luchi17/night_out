
//  ContentView.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var locations: [LocationModel]
    var onSelectLocation: ((LocationModel, CGPoint) -> Void)?
    var onRegionChange: ((MKCoordinateRegion) -> Void)?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true // Muestra la ubicación del usuario
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
            uiView.setRegion(region, animated: true)

            uiView.removeAnnotations(uiView.annotations)

            // Agregar las anotaciones
            let annotations = locations.map { location in
                let annotation = MKPointAnnotation()
                annotation.title = location.name
                annotation.coordinate = location.coordinate
                return annotation
            }

            uiView.addAnnotations(annotations)
        }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        // Manejo de la vista de anotaciones
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // No cambiar la anotación de la ubicación del usuario
            }
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "discoteca")
            annotationView.markerTintColor = .blue // Color del pin
            annotationView.canShowCallout = true // Muestra el nombre de la discoteca
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Cuando la región cambia, llamamos al closure onRegionChange
            DispatchQueue.main.async {
                self.parent.onRegionChange?(mapView.region)
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation,
                  let title = view.annotation?.title,
                  let selectedLocation = parent.locations.first(where: { $0.name == title })
            else { return }

            // Convertir las coordenadas de la anotación a la vista
            let annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)
            
            // Llamar al closure cuando se selecciona un lugar
            parent.onSelectLocation?(selectedLocation, annotationPoint)
        }
    }
}
