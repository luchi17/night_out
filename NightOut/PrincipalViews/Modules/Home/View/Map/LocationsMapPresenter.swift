import SwiftUI
import Combine
import CoreLocation
import MapKit

final class LocationsMapViewModel: ObservableObject {
    
    @Published var searchQuery: String = ""
    @Published var locations: [LocationModel] = [] // Lista de discotecas recibida de API
    @Published var selectedLocation: LocationModel? // Discoteca seleccionada
    
    @Published var locationManager: LocationManager
    @Published var filteredLocations: [LocationModel] = []
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
}

protocol LocationsMapPresenter {
    var viewModel: LocationsMapViewModel { get }
    func transform(input: LocationsMapPresenterImpl.ViewInputs)
}

final class LocationsMapPresenterImpl: LocationsMapPresenter {
    
    struct UseCases {
        
    }
    
    struct Actions {
        let onOpenMaps: InputClosure<(Double, Double)>
    }
    
    struct ViewInputs {
        let openMaps: AnyPublisher<(Double, Double), Never>
        let onFilterSelected: AnyPublisher<MapFilterType, Never>
        let locationBarSearch: AnyPublisher<Void, Never>
        let regionChanged: AnyPublisher<MKCoordinateRegion, Never>
        let locationSelected: AnyPublisher<LocationModel, Never>
    }
    
    var viewModel: LocationsMapViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions,
        locationManager: LocationManager
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = LocationsMapViewModel(locationManager: locationManager)
    }
    
    func transform(input: LocationsMapPresenterImpl.ViewInputs){
        input
            .openMaps
            .withUnretained(self)
            .sink { presenter, data in
                self.actions.onOpenMaps(data)
            }
            .store(in: &cancellables)
        
        input
            .onFilterSelected
            .withUnretained(self)
            .sink { presenter, filter in
                //DO LOGIC, ROW BELOW WRONG
                // update viewmodel locations
                self.viewModel.filteredLocations = self.viewModel.locationManager.locations
                // Call use case to retrieve locations according to the type selected
            }
            .store(in: &cancellables)
        
        input
            .locationBarSearch
            .withUnretained(self)
            .sink { presenter, _ in
                self.searchSpecificLocation()
            }
            .store(in: &cancellables)
        
        input
            .regionChanged
            .withUnretained(self)
            .sink { presenter, newRegion in
                self.viewModel.locationManager.regionDidChange(
                    to: newRegion,
                    query: self.viewModel.searchQuery
                )
            }
            .store(in: &cancellables)
        
        input
            .locationSelected
            .withUnretained(self)
            .sink { presenter, locationSelected in
                // Update map to move to the specific location
                // sirve actualizar con la region como en searchSpecificLocation ?
                self.viewModel.filteredLocations = []
            }
            .store(in: &cancellables)
            
    }
    
    private func searchSpecificLocation() {
        // Filtrar discotecas en base al searchQuery
        if let selectedLocation = viewModel.locations.first(where: { $0.name.lowercased().contains(viewModel.searchQuery.lowercased()) }) {
            viewModel.selectedLocation = selectedLocation
            let newRegion = MKCoordinateRegion(center: selectedLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            viewModel.locationManager.regionDidChange(
                to: newRegion,
                query: viewModel.searchQuery
            )
        }
    }
}
