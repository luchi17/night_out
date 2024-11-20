import Foundation
import _MapKit_SwiftUI
import MapKit

struct LocationModel: Identifiable, Hashable {
    let id: String
    var name: String
    var coordinate: LocationCoordinate
    var image: String? = ""
    var startTime: String? = ""
    var endTime: String? = ""
    var selectedTag: LocationSelectedTag?
    var usersGoing: Int
    var distanceToUser: Double
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(id: String = UUID().uuidString, name: String = "", coordinate: LocationCoordinate = LocationCoordinate(), image: String? = nil, startTime: String? = nil, endTime: String? = nil, selectedTag: LocationSelectedTag? = LocationSelectedTag.none, usersGoing: Int  = 0, distanceToUser: Double = 0.0) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.image = image
        self.startTime = startTime
        self.endTime = endTime
        self.selectedTag = selectedTag
        self.usersGoing = usersGoing
        self.distanceToUser = distanceToUser
    }
}


struct LocationCoordinate: Identifiable, Hashable {
    let id: String
    let location: CLLocationCoordinate2D

    static func == (lhs: LocationCoordinate, rhs: LocationCoordinate) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(id: String = UUID().uuidString, location: CLLocationCoordinate2D = CLLocationCoordinate2D()) {
        self.id = id
        self.location = location
    }
}
