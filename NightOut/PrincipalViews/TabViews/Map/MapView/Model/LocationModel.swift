import Foundation
import MapKit

struct LocationModel: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let description: String // Agregar una descripción para mostrar
}
