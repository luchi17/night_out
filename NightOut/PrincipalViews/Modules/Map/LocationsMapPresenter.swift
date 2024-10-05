import SwiftUI
import Combine
import CoreLocation
import MapKit

final class LocationsMapViewModel: ObservableObject {
    
    @Published var searchQuery: String = ""
    @Published var locations: [LocationModel] = [] // Lista de discotecas recibida de API
    @Published var selectedLocation: LocationModel? // Discoteca seleccionada
    
    @Published var locationManager: LocationManager
    
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
        let onFilterSelected: InputClosure<MapFilterType>
    }
    
    struct ViewInputs {
        let openMaps: AnyPublisher<(Double, Double), Never>
        let onFilterSelected: AnyPublisher<MapFilterType, Never>
        let locationBarSearch: AnyPublisher<Void, Never>
        let regionChanged: AnyPublisher<MKCoordinateRegion, Never>
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
            .sink { presenter, data in
                self.actions.onFilterSelected(data)
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
