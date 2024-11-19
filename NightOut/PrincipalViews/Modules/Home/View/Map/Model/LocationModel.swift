import Foundation
import MapKit

struct LocationModel: Identifiable, Equatable {
    let id: String
    var name: String = ""
    var coordinate = CLLocationCoordinate2D()
    var image: String? = ""
    var startTime: String? = ""
    var endTime: String? = ""
    var selectedTag: LocationSelectedTag? = LocationSelectedTag.none
    var usersGoing: Int = 0
    var distanceToUser: Double = 0.0
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
