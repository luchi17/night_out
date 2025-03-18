import SwiftUI
import Combine
import CoreLocation
import MapKit
import Firebase

final class LocationsMapViewModel: ObservableObject {
    
    @Published var selectedMarkerLocation: LocationModel? // Discoteca seleccionada
    @Published var selectedMarkerFromList: LocationModel? // Discoteca seleccionada
    
    @Published var locationManager: LocationManager
    @Published var allClubsModels: [LocationModel] = []
    @Published var currentShowingLocationList: [LocationModel] = []
    
    @Published var loading: Bool = false
    @Published var toastError: ToastType?
    @Published var followingPeople: [String] = []

    
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
        let goToProfile: InputClosure<ProfileModel>
        let goToPrivateProfile: InputClosure<ProfileModel>
    }
    
    struct ViewInputs {
        let openMaps: AnyPublisher<(Double, Double), Never>
        let openAppleMaps: AnyPublisher<(CLLocationCoordinate2D, String?), Never>
        let onFilterSelected: AnyPublisher<MapFilterType, Never>
        let locationInListSelected: AnyPublisher<LocationModel, Never>
        let viewDidLoad: AnyPublisher<Void, Never>
        let goToProfile: AnyPublisher<LocationModel, Never>
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
            .flatMap { presenter, data -> AnyPublisher<([(String, Int)], [CompanyModel], [String]?), Never> in
                let companies = data.0?.users.map({ $0.value }) ?? []
                let followingPeople = Array(data.1.keys)
                
                return presenter.getClubAssistance(companies: companies, followingPeople: followingPeople)
                    .map({ ($0, companies, followingPeople) })
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink(receiveValue: { presenter, data in
                let assistance = data.0
                let companies = data.1
                let followingPeople = data.2
                
                presenter.viewModel.followingPeople = followingPeople ?? []
                
                if !companies.isEmpty {
                    presenter.viewModel.toastError = nil
                    
                    let allClubsModel = companies.compactMap { companyModel in
                        
                        presenter.transformCompanyModel(
                            companyModel,
                            assistance: assistance
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
                presenter.viewModel.selectedMarkerLocation = nil
                presenter.viewModel.selectedMarkerFromList = locationSelected
            }
            .store(in: &cancellables)
        
        input
            .goToProfile
            .withUnretained(self)
            .sink { presenter, locationModel in
                
                let following = presenter.viewModel.followingPeople
                
                let companyModel = UserDefaults.getCompanies()?.users.values.first(where: { $0.uid == locationModel.id })
                let profileModel = ProfileModel(
                    profileImageUrl: locationModel.image,
                    username: locationModel.name,
                    fullname: companyModel?.fullname,
                    profileId: locationModel.id,
                    isCompanyProfile: true,
                    isPrivateProfile: companyModel?.profileType == .privateProfile
                )
                
                if following.contains(locationModel.id) {
                    presenter.actions.goToProfile(profileModel)
                } else {
                    if profileModel.isPrivateProfile {
                        presenter.actions.goToPrivateProfile(profileModel)
                    } else {
                        presenter.actions.goToProfile(profileModel)
                    }
                }
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
    
    func getClubAssistance(companies: [CompanyModel], followingPeople: [String]) -> AnyPublisher<[(String, Int)], Never> {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let currentDate = dateFormatter.string(from: Date())
        
        let publishers: [AnyPublisher<(String, Int), Never>] = companies.map { company in
            
            let clubRef = FirebaseServiceImpl.shared.getClub().child(company.uid).child("Assistance").child(currentDate)
            
            return Future { promise in
                clubRef.getData { error, snapshot in
                    guard error == nil, let clubSnapshot = snapshot else {
                        promise(.success((company.uid, 0)))
                        return
                    }
                    
                    let clubAttendees = Set(clubSnapshot.children.compactMap { ($0 as? DataSnapshot)?.key })
                    let following = Set(followingPeople)
                    let commonCount = following.intersection(clubAttendees).count
                    promise(.success((company.uid, commonCount)))
                }
            }
            .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    func transformCompanyModel(_ companyModel: CompanyModel, assistance: [(String, Int)]) -> LocationModel? {
        
        if let location = companyModel.location,
           let coordinates = viewModel.locationManager.getCoordinatesFromString(location) {
            
            return LocationModel(
                id: companyModel.uid,
                name: companyModel.username ?? "",
                coordinate: LocationCoordinate(id: companyModel.uid, location: coordinates),
                image: companyModel.imageUrl,
                startTime: companyModel.startTime,
                endTime: companyModel.endTime,
                selectedTag: LocationSelectedTag(rawValue: companyModel.selectedTag),
                followingGoing: assistance.first(where: { $0.0 == companyModel.uid })?.1 ?? 0
            )
        }
        return nil
    }
        
}
