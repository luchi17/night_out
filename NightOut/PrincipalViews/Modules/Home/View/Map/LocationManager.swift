import Foundation
import CoreLocation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    public static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    
    @Published var region: MKCoordinateRegion?
    @Published var userRegion = MKCoordinateRegion()
    @Published var query: String = ""
    @Published var locations: [LocationModel] = []
    @Published var locationPermissionDenied = false // Variable para permisos de localización
    
    @Published var userLocation = LocationCoordinate()
    
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
        guard let location = locations.last else { return }
        let userRegion = MKCoordinateRegion(center: location.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        self.userLocation = LocationCoordinate(location: userRegion.center)
        self.userRegion = userRegion
    }
    
    func updateRegion(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        self.region = region
    }
    
    func searchLocation(searchQuery: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, let item = response.mapItems.first else {
                print("Ubicación no encontrada: \(error?.localizedDescription ?? "Error desconocido")")
                return
            }
            DispatchQueue.main.async {
                self.updateRegion(coordinate: item.placemark.coordinate)
                self.locations.append(
                    LocationModel(
                        name: item.name ?? "Sin Nombre",
                        coordinate: LocationCoordinate(location: item.placemark.coordinate),
                        image: ""
                    )
                )
            }
        }
    }
    
    func areLocationsEqual(location1: CLLocationDegrees, location2: CLLocationDegrees, decimalPlaces: Int) -> Bool {
        let factor = pow(10.0, Double(decimalPlaces))
        let roundedLocation1 = (location1 * factor).rounded() / factor
        let roundedLocation2 = (location2 * factor).rounded() / factor
        return roundedLocation1 == roundedLocation2
    }

    func areCoordinatesEqual(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D, decimalPlaces: Int = 5) -> Bool {
        let latitudeEqual = areLocationsEqual(
            location1: coordinate1.latitude,
            location2: coordinate2.latitude,
            decimalPlaces: decimalPlaces
        )
        let longitudeEqual = areLocationsEqual(
            location1: coordinate1.longitude,
            location2: coordinate2.longitude,
            decimalPlaces: decimalPlaces
        )
        return latitudeEqual && longitudeEqual
    }
}
