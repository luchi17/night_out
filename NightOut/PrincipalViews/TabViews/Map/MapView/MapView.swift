
//  ContentView.swift
//  NightOut
//
//  Created by Apple on 27/9/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [MKPointAnnotation]
    var onRegionChange: ((MKCoordinateRegion) -> Void)?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true // Muestra la ubicación del usuario
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annotations) // Añade los pines (anotaciones) de discotecas
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
            parent.onRegionChange?(mapView.region)
        }
    }
}
