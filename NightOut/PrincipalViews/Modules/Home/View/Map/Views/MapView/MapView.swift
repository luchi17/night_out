//
////  ContentView.swift
////  NightOut
////
////  Created by Apple on 27/9/24.
////
//
//import SwiftUI
//import MapKit
//
//struct MapView: UIViewRepresentable {
//    @Binding var region: MKCoordinateRegion
//    @Binding var locations: [LocationModel]
//    var onSelectLocation: ((LocationModel, CGPoint) -> Void)?
//    var onRegionChange: ((MKCoordinateRegion) -> Void)? = nil
//    var forceUpdateView: Bool = false
//    
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        mapView.showsUserLocation = true // Muestra la ubicación del usuario
//        mapView.setRegion(region, animated: true)
//        return mapView
//    }
//    
//    func updateUIView(_ uiView: MKMapView, context: Context) {
//        let regionChanged = !LocationManager.shared.areCoordinatesEqual(
//            coordinate1: uiView.region.center,
//            coordinate2: region.center,
//            decimalPlaces: 6
//        )
//        if (regionChanged || forceUpdateView) {
//            updateView(uiView)
//        } else {
//            print("same region")
//        }
//    }
//    
//    func updateView(_ uiView: MKMapView) {
//        print(region)
//        uiView.setRegion(region, animated: true)
//        
//        uiView.removeAnnotations(uiView.annotations)
//        
//        // Agregar las anotaciones
//        let annotations = locations.map { location in
//            let annotation = MKPointAnnotation()
//            annotation.title = location.name
//            annotation.coordinate = location.
//            return annotation
//        }
//        
//        uiView.addAnnotations(annotations)
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, MKMapViewDelegate {
//        var parent: MapView
//        var isRegionBeingUpdated = false // Bloqueo temporal para evitar sobrescritura de región
//
//        
//        init(_ parent: MapView) {
//            self.parent = parent
//        }
//        
//        // Manejo de la vista de anotaciones
//        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//            guard annotation is MKPointAnnotation else { return nil }
//            
//            let identifier = "CustomAnnotation"
//            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomAnnotationViewWrapper
//            if annotationView == nil {
//                annotationView = CustomAnnotationViewWrapper(annotation: annotation, reuseIdentifier: identifier)
//            } else {
//                annotationView?.annotation = annotation
//            }
//            
//            annotationView?.setupContent()
//            annotationView?.canShowCallout = true
//            
//            return annotationView
//        }
//        
//        // Remove ?
//        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//            parent.region = mapView.region
//        }
//        
//        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//            guard let annotation = view.annotation,
//                  let title = view.annotation?.title,
//                  let selectedLocation = parent.locations.first(where: { $0.name == title })
//            else { return }
//            
//            // Convertir las coordenadas de la anotación a la vista
//            let annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)
//            
//            // Llamar al closure cuando se selecciona un lugar
//            parent.onSelectLocation?(selectedLocation, annotationPoint)
//        }
//    }
//}
