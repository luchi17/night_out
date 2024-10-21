import Foundation
import CoreLocation
import MapKit
import Combine

#warning("TODO: get locations from user")
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    public static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    
    @Published var region = MKCoordinateRegion()
    @Published var query: String = ""
    @Published var locations: [LocationModel] = []
    @Published var locationPermissionDenied = false // Variable para permisos de localización
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Manejar cambios en el estado de autorización
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            locationPermissionDenied = true
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionDenied = false
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    // Método para manejar las actualizaciones de ubicación
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let region = MKCoordinateRegion(center: location.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        fetchNearbyPlaces(region: region, query: self.query)
    }
    
    // Método para buscar lugares cercanos
    func fetchNearbyPlaces(region: MKCoordinateRegion, query: String) {
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        self.query = query
        self.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            
            var newLocations: [LocationModel] = []
            for item in response.mapItems {
                let model = LocationModel(
                    name: item.name ?? "Sin Nombre",
                    coordinate: item.placemark.coordinate,
                    description: "Descripción de \(item.name ?? "Sin Nombre")",
                    image: ""
                ) // Aquí puedes agregar más info
                newLocations.append(model)
            }
            DispatchQueue.main.async {
                self.locations = newLocations
            }
        }
    }
    
    func regionDidChange(to newRegion: MKCoordinateRegion, query: String) {
        fetchNearbyPlaces(region: newRegion, query: query) // Actualizar la búsqueda de lugares cercanos
    }
}

