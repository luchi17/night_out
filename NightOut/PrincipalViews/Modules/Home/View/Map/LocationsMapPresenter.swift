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
    @Published var allClubsLocations: [LocationModel] = []
    
    @Published var loading: Bool = false
    @Published var toastError: ToastType?
    
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
        let companyLocationsUseCase: CompanyLocationsUseCase
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
        let viewDidLoad: AnyPublisher<Void, Never>
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
        listenToInput(input: input)

        input
            .viewDidLoad
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.companyLocationsUseCase.fetchCompanyLocations()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { _ in })
            .withUnretained(self)
            .sink(receiveValue: { presenter, data in
                if let data = data {
                    presenter.viewModel.toastError = nil
                    
                    let locations = data.users.values.compactMap({ $0 })
                    
                    let allClubsModel = locations.compactMap { companyModel in
                        if let components = companyModel.location?.split(separator: ","),
                           components.indices.contains(0), components.indices.contains(1),
                            let latitude = Double(components[0]),
                           let longitude = Double(components[1]) {
                            return LocationModel(
                                name: companyModel.username ?? "",
                                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                description: companyModel.selectedTag,
                                image: companyModel.imageUrl,
                                startTime: companyModel.startTime,
                                endTime: companyModel.endTime,
                                selectedTag: LocationSelectedTag(rawValue: companyModel.selectedTag),
                                usersGoing: 0
                            )
                        }
                        return nil
                    }
                    
                    presenter.viewModel.allClubsLocations = allClubsModel
                    
                    
                } else {
                    guard !presenter.viewModel.loading else { return }
                    self.viewModel.toastError = .custom(.init(title: "Error", description: "Could not load companies locations.", image: nil))
                }
                
            })
            .store(in: &cancellables)
        
        
//        input
//            .viewDidLoad
//            .withUnretained(self)
//            .performRequest(request: { presenter, _ in
//                presenter.useCases.companyLocationsUseCase.fetchAttendanceData()
//                    
//            }, loadingClosure: { [weak self] loading in
//                guard let self = self else { return }
////                self.viewModel.loading = loading
//            }, onError: { [weak self] error in
//                guard let self = self else { return }
////                if error == nil {
////                    self.viewModel.headerError = nil
////                } else {
////                    guard self.viewModel.loading else { return }
////                    self.viewModel.headerError = ErrorState(errorOptional: error)
////                }
//            })
//            .sink(receiveValue: { [weak self] data in
//                print("DATA")
//                print(data)
//            })
//            .store(in: &cancellables)
        
            
    }
    
    func listenToInput(input: LocationsMapPresenterImpl.ViewInputs){
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
