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

#warning("TODO: usersGoing")
#warning("PENDING: filtered locations")

        
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
                let searchedLocationCcoordinate = self.viewModel.locationManager.checkKnownLocationCoordinate(searchQuery: self.viewModel.searchQuery)
                let allClubsCoordinates = self.viewModel.allClubsLocations.map({ $0.coordinate })
                
                let foundClub = allClubsCoordinates.first(where: {
                    self.viewModel.locationManager.areCoordinatesEqual(
                        coordinate1: $0,
                        coordinate2: searchedLocationCcoordinate
                )})
                
                if let foundClub = foundClub {
                    self.viewModel.locationManager.updateRegion(coordinate: foundClub)
                }
                else {
                    #warning("TODO: Show message error of club not found?")
                }
            }
            .store(in: &cancellables)
        
        
        viewModel
            .$selectedLocation
            .withUnretained(self)
            .sink { presenter, locationSelected in
                if let coordinate = locationSelected?.coordinate {
                    self.viewModel.locationManager.updateRegion(coordinate: coordinate)
                }
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
}
