
import SwiftUI
import Combine

class HomeCoordinator {
    
    private let actions: HomePresenterImpl.Actions
    private let mapActions: LocationsMapPresenterImpl.Actions
    private let locationManager: LocationManager
    
    init(actions: HomePresenterImpl.Actions, mapActions: LocationsMapPresenterImpl.Actions, locationManager: LocationManager) {
        self.actions = actions
        self.mapActions = mapActions
        self.locationManager = locationManager
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = HomePresenterImpl(
            useCases: .init(),
            actions: actions
        )
        let mapPresenter = LocationsMapPresenterImpl(
            useCases: .init(),
            actions: mapActions,
            locationManager: locationManager
        )
        HomeView(presenter: presenter, mapPresenter: mapPresenter)
    }
}

