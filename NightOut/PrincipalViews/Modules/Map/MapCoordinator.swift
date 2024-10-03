
import SwiftUI
import Combine

class MapCoordinator {
    
    private let openMaps: (Double, Double) -> Void
    
    init(openMaps: @escaping (Double, Double) -> Void) {
        self.openMaps = openMaps
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = LocationsMapPresenterImpl(
            useCases: .init(),
            actions: .init(onOpenMaps: openMaps)
        )
        LocationsMapView(presenter: presenter)
    }
}
