
import SwiftUI
import Combine

class MapCoordinator {
    
    private let actions: LocationsMapPresenterImpl.Actions
    private let locationManager: LocationManager
    
    init(actions: LocationsMapPresenterImpl.Actions, locationManager: LocationManager) {
        self.actions = actions
        self.locationManager = locationManager
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = LocationsMapPresenterImpl(
            useCases: .init(),
            actions: actions,
            locationManager: locationManager
        )
        LocationsMapView(presenter: presenter)
    }
}
