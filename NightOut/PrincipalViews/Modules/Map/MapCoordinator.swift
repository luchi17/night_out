
import SwiftUI
import Combine

class MapCoordinator: ObservableObject {
    
    private let openMaps: (Double, Double) -> Void
    
    init(openMaps: @escaping (Double, Double) -> Void) {
        self.openMaps = openMaps
    }
    
    func start() -> LocationsMapView {
        let presenter = LocationsMapPresenterImpl(
            useCases: .init(),
            actions: .init(onOpenMaps: openMaps)
        )
        return LocationsMapView(presenter: presenter)
    }
}
