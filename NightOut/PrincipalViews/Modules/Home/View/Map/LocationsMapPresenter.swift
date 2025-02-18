import SwiftUI
import Combine
import CoreLocation
import MapKit

#warning("Add cache of companies with UserDefaults.getCompanies() ")
final class LocationsMapViewModel: ObservableObject {
    
    @Published var selectedMarkerLocation: LocationModel? // Discoteca seleccionada
    
    @Published var locationManager: LocationManager
    @Published var allClubsModels: [LocationModel] = []
    @Published var currentShowingLocationList: [LocationModel] = []
    
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
        let followUseCase: FollowUseCase
        let clubUseCase: ClubUseCase
    }
    
    struct Actions {
        let onOpenMaps: InputClosure<(Double, Double)>
        let onOpenAppleMaps: InputClosure<(CLLocationCoordinate2D, String?)>
    }
    
    struct ViewInputs {
        let openMaps: AnyPublisher<(Double, Double), Never>
        let openAppleMaps: AnyPublisher<(CLLocationCoordinate2D, String?), Never>
        let onFilterSelected: AnyPublisher<MapFilterType, Never>
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
            .flatMap({ presenter, companyUsers -> AnyPublisher<(CompanyUsersModel?, [String: Bool]), Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just((companyUsers, [:])).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: uid)
                    .map { followModel in
                        return (companyUsers, followModel?.following ?? [:])
                    }
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .flatMap { presenter, data -> AnyPublisher<([(String, [String])], [String], [CompanyModel]), Never> in
                let companies = data.0?.users.map({ $0.value }) ?? []
                let followingPeople = Array(data.1.keys)
                
                return presenter.getClubAssistance(companies: companies)
                    .map({ ($0, followingPeople, companies) })
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink(receiveValue: { presenter, data in
                let assistance = data.0
                let followingPeople = data.1
                let companies = data.2

                if !companies.isEmpty {
                    presenter.viewModel.toastError = nil
                    
                    let allClubsModel = companies.compactMap { companyModel in
                        
                        presenter.transformCompanyModel(
                            companyModel,
                            assistance: assistance,
                            followingPeople: followingPeople
                        )
                    }
                    presenter.viewModel.currentShowingLocationList = allClubsModel
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
            .openAppleMaps
            .withUnretained(self)
            .sink { presenter, data in
                presenter.actions.onOpenAppleMaps(data)
            }
            .store(in: &cancellables)
        
        input
            .onFilterSelected
            .withUnretained(self)
            .sink { presenter, filter in
                switch filter {
                case .near:
                    let userCoordinates = presenter.viewModel.locationManager.userRegion.center
                    let sortedClubsByDistance = presenter.viewModel.allClubsModels.map { club in
                        var updatedClub = club
                        let distance = presenter.calculateDistance(
                            from: userCoordinates,
                            to: club.coordinate.location
                        )
                        updatedClub.distanceToUser = distance
                        return updatedClub
                    }
                        .sorted { club1, club2 in
                             return club1.distanceToUser < club2.distanceToUser
                        }
                    
                    presenter.viewModel.currentShowingLocationList = sortedClubsByDistance
                    
                case .people:
                    let sortedClubsByUsersGoing = presenter.viewModel.allClubsModels.sorted { $0.followingGoing > $1.followingGoing }
                    presenter.viewModel.currentShowingLocationList = sortedClubsByUsersGoing
                }
                
            }
            .store(in: &cancellables)
        
        input
            .locationInListSelected
            .withUnretained(self)
            .sink { presenter, locationSelected in
                presenter.viewModel.selectedMarkerLocation = locationSelected
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
    
    func getClubAssistance(companies: [CompanyModel]) -> AnyPublisher<[(String, [String])], Never> {
        
        let publishers: [AnyPublisher<(String, [String]), Never>] = companies.map { company in
            
            return useCases.clubUseCase.getAssistance(profileId: company.uid)
                .map { clubAssistance in
                    return (company.uid, Array(clubAssistance.keys))
                }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    func transformCompanyModel(_ companyModel: CompanyModel, assistance: [(String, [String])], followingPeople: [String]) -> LocationModel? {
        
        if let location = companyModel.location,
           let coordinates = viewModel.locationManager.getCoordinatesFromString(location) {
            
            let matchingAssistance = assistance.first(where: { $0.0 == companyModel.uid })
            
            let usersGoingToClub = matchingAssistance?.1
            
            let followingUsersMatchingAssistance = usersGoingToClub?.filter({ userGoing in
                followingPeople.contains(where: { userGoing == $0 })
            })
            
            return LocationModel(
                id: companyModel.uid,
                name: companyModel.username ?? "",
                coordinate: LocationCoordinate(id: companyModel.uid, location: coordinates),
                image: companyModel.imageUrl,
                startTime: companyModel.startTime,
                endTime: companyModel.endTime,
                selectedTag: LocationSelectedTag(rawValue: companyModel.selectedTag),
                followingGoing: followingUsersMatchingAssistance?.count ?? 0
            )
        }
        return nil
    }
}
