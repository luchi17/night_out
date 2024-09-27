
import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default location (San Francisco)
                                               span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @Published var discotecas: [MKPointAnnotation] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // Solicitar permiso de localización
        locationManager.startUpdatingLocation()
    }

    // Este método se llama cuando el usuario permite la localización y se actualiza la ubicación
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        region = MKCoordinateRegion(center: location.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        fetchNearbyDiscotecas(location: location)
    }

    // Método para buscar discotecas cercanas
    func fetchNearbyDiscotecas(location: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Discoteca"
        request.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }

            var newAnnotations: [MKPointAnnotation] = []
            for item in response.mapItems {
                let annotation = MKPointAnnotation()
                annotation.title = item.name
                annotation.coordinate = item.placemark.coordinate
                newAnnotations.append(annotation)
            }
            DispatchQueue.main.async {
                self.discotecas = newAnnotations
            }
        }
    }
}
