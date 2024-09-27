import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                                               span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @Published var query: String = ""
    @Published var locations: [LocationModel] = []
    @Published var locationPermissionDenied = false // Variable para permisos de localización
    
    override init() {
        super.init()
        locationManager.delegate = self
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
        region = MKCoordinateRegion(center: location.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        fetchNearbyPlaces(region: region, query: self.query)
    }
    
    // Método para buscar lugares cercanos
    func fetchNearbyPlaces(region: MKCoordinateRegion, query: String) {
        guard let location = self.locationManager.location else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query // Filtro
        request.region = region
        
        self.query = query
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            
            var newLocations: [LocationModel] = []
            for item in response.mapItems {
                let model = LocationModel(name: item.name ?? "Sin Nombre",
                                             coordinate: item.placemark.coordinate,
                                             description: "Descripción de \(item.name ?? "Sin Nombre")") // Aquí puedes agregar más info
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

