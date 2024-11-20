import SwiftUI
import Combine
import CoreLocation
import MapKit

final class LocationsMapViewModel: ObservableObject {
    
    @Published var searchQuery: String = ""
    @Published var locations: [LocationModel] = [] // Lista de discotecas recibida de API
    @Published var selectedMarkerLocation: LocationModel? // Discoteca seleccionada
    
    @Published var locationManager: LocationManager
    @Published var filteredLocations: [LocationModel] = []
    @Published var allClubsModels: [LocationModel] = []
    @Published var selectedFilter: MapFilterType?
    
    @Published var loading: Bool = false
    @Published var toastError: ToastType?
    @Published var forceUpdateMapView: Bool = false
    
    
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
        let locationInListSelected: AnyPublisher<LocationModel, Never>
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
        
         let companyModelsPublisher = input
                    .viewDidLoad
                    .withUnretained(self)
                    .performRequest(request: { presenter, _ in
                        presenter.useCases.companyLocationsUseCase.fetchCompanyLocations()
                    }, loadingClosure: { [weak self] loading in
                        guard let self = self else { return }
                        self.viewModel.loading = loading
                    }, onError: { _ in })
                    .eraseToAnyPublisher()
        
        companyModelsPublisher
            .withUnretained(self)
            .flatMap { presenter, companyUsers -> AnyPublisher<(CompanyUsersModel?, [String: Int]), Never> in
                presenter.useCases.companyLocationsUseCase.fetchAttendanceData()
                    .map { attendanceData in
                        return (companyUsers, attendanceData)
                    }
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink(receiveValue: { presenter, data in
                let companyUsers = data.0
                let attendanceData = data.1
                
                if let companyUsers = companyUsers {
                    presenter.viewModel.toastError = nil
                    
                    let locations = companyUsers.users.values.compactMap({ $0 })
                    
                    let allClubsModel = locations.compactMap { companyModel in
                        if let components = companyModel.location?.split(separator: ","),
                           components.indices.contains(0), components.indices.contains(1),
                           let latitude = Double(components[0]),
                           let longitude = Double(components[1]) {
                            return LocationModel(
                                id: companyModel.uid,
                                name: companyModel.username ?? "",
                                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                image: companyModel.imageUrl,
                                startTime: companyModel.startTime,
                                endTime: companyModel.endTime,
                                selectedTag: LocationSelectedTag(rawValue: companyModel.selectedTag),
                                usersGoing: attendanceData[companyModel.uid] ?? 0
                            )
                        }
                        return nil
                    }
                    presenter.viewModel.forceUpdateMapView = true
                    presenter.viewModel.allClubsModels = allClubsModel
                    
                } else {
                    guard !presenter.viewModel.loading else { return }
                    presenter.viewModel.toastError = .custom(.init(title: "Error", description: "Could not load companies locations.", image: nil))
                }
            })
            .store(in: &cancellables)
        
    }
    
    func listenToInput(input: LocationsMapPresenterImpl.ViewInputs){
        input
            .openMaps
            .withUnretained(self)
            .sink { presenter, data in
                presenter.actions.onOpenMaps(data)
            }
            .store(in: &cancellables)

        input
            .onFilterSelected
            .withUnretained(self)
            .sink { presenter, filter in
                presenter.viewModel.selectedFilter = filter
                switch filter {
                case .near:
                    let userCoordinates = presenter.viewModel.locationManager.userRegion.center
                    let sortedClubsByDistance = presenter.viewModel.allClubsModels.map { club in
                        var updatedClub = club
                        let distance = presenter.calculateDistance(
                            from: userCoordinates,
                            to: club.coordinate
                        )
                        updatedClub.distanceToUser = distance
                        return updatedClub
                    }
                    .sorted {$0.distanceToUser < $1.distanceToUser }
                    
                    presenter.viewModel.filteredLocations = sortedClubsByDistance
                    
                case .people:
                    let sortedClubsByUsersGoing = presenter.viewModel.allClubsModels.sorted { $0.usersGoing > $1.usersGoing }
                    presenter.viewModel.filteredLocations = sortedClubsByUsersGoing
                }
                
            }
            .store(in: &cancellables)
        
#warning("check with existing location")
        input
            .locationBarSearch
            .withUnretained(self)
            .sink { presenter, _ in
                
//                presenter.viewModel.forceUpdateMapView = true
                
                presenter.viewModel.locationManager.checkKnownLocationCoordinate(searchQuery: presenter.viewModel.searchQuery) { searchedLocationCoordinate in
                        
                    let allClubsCoordinates = self.viewModel.allClubsModels.map({ $0.coordinate })
                    
                    let foundClub = allClubsCoordinates.first(where: {
                        let hola = presenter.viewModel.locationManager.areCoordinatesEqual(
                            coordinate1: $0,
                            coordinate2: searchedLocationCoordinate
                        )
                        return hola
                    })
                    
                    if let foundClub = foundClub {
                        presenter.viewModel.locationManager.updateRegion(coordinate: foundClub)
                    }
                    else {
                        presenter.viewModel.toastError = .custom(.init(title: "Error", description: "Club not found", image: nil))
                    }
                }
               
            }
            .store(in: &cancellables)
        
        
        viewModel
            .$selectedMarkerLocation
            .withUnretained(self)
            .sink { presenter, locationSelected in
                if let coordinate = locationSelected?.coordinate {
                    presenter.viewModel.locationManager.updateRegion(coordinate: coordinate)
                }
            }
            .store(in: &cancellables)
        
        input
            .locationInListSelected
            .withUnretained(self)
            .sink { presenter, locationSelected in
                presenter.viewModel.forceUpdateMapView = true
                presenter.viewModel.locationManager.updateRegion(coordinate: locationSelected.coordinate)
            }
            .store(in: &cancellables)
    }
}

private extension LocationsMapPresenterImpl {
    func calculateDistance(from current: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let currentLoc = CLLocation(latitude: current.latitude, longitude: current.longitude)
        let destLoc = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return currentLoc.distance(from: destLoc)
    }
    
}
