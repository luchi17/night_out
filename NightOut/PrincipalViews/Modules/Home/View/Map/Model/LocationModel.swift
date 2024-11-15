import Foundation
import MapKit

struct LocationModel: Identifiable, Equatable {
    let id = UUID()
    var name: String = ""
    var coordinate = CLLocationCoordinate2D()
    var description: String? = "" // Agregar una descripción para mostrar
    var image: String? = ""
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
