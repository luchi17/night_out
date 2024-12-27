import SwiftUI
import Combine


struct ProfileModel {
    var profileImageUrl: String?
    var username: String?
    var fullname: String?
    var profileId: String
    var isCompanyProfile: Bool
}

enum FollowButtonType {
    case following
    case follow
    
    var title: String {
        switch self {
        case .follow:
            return "Follow"
        case .following:
            return "Following"
        }
    }
}

enum ImGoingToClub {
    case going
    case notGoing
    
    var whiskyImage: Image {
        switch self {
        case .going:
            return Image("whisky_full")
        case .notGoing:
            return Image("whisky_empty")
        }
    }
}

//From notifications when
//val fragment = if (notification.getIsPost()) {
//                PostDetailsFragment(notification.postId)
//            } else {
//                Profile3Fragment(notification.userId)
//            }

//From Maps when tapping on marker

final class UserProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = ""
    @Published var fullname: String = ""
    @Published var followButtonType: FollowButtonType?

    @Published var imGoingToClub: ImGoingToClub = .notGoing
    @Published var usersGoingToClub: [UserModel] = []
    @Published var followingPeopleGoingToClub: [UserModel] = []
    
    @Published var myCurrentClubModel: CompanyModel?
    @Published var isCompanyProfile: Bool
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    
    init(profileImageUrl: String?, username: String?, fullname: String?, isCompanyProfile: Bool) {
        self.profileImageUrl = profileImageUrl
        self.username = username ?? "Nombre no disponible"
        self.fullname = fullname ?? "Username no disponible"
        self.isCompanyProfile = isCompanyProfile
    }
    
}

protocol UserProfilePresenter {
    var viewModel: UserProfileViewModel { get }
    func transform(input: UserProfilePresenterImpl.ViewInputs)
}

final class UserProfilePresenterImpl: UserProfilePresenter {
    
    struct UseCases {
        let followUseCase: FollowUseCase
        let userDataUseCase: UserDataUseCase
        let clubUseCase: ClubUseCase
        let noficationsUsecase: NotificationsUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
        let goBack: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let followProfile: AnyPublisher<Void, Never>
        let goToClub: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
        let onUserSelected: AnyPublisher<UserGoingCellModel, Never>
    }
    
    var viewModel: UserProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private var model: ProfileModel
    
    let myUid = FirebaseServiceImpl.shared.getCurrentUserUid() ?? ""

    init(
        useCases: UseCases,
        actions: Actions,
        model: ProfileModel
    ) {
        self.actions = actions
        self.useCases = useCases
        self.model = model
        
        
        viewModel = UserProfileViewModel(
            profileImageUrl: model.profileImageUrl,
            username: model.username,
            fullname: model.fullname,
            isCompanyProfile: model.isCompanyProfile
        )
    }
    
    func transform(input: UserProfilePresenterImpl.ViewInputs) {
        
        listenToInputs(input: input)
        
        let followObserver =
            useCases.followUseCase.observeFollow(id: myUid)
                .eraseToAnyPublisher()
        
        //Just for companies
        let assistanceObserver =
            useCases.clubUseCase.observeAssistance(profileId: self.model.profileId)
                    .withUnretained(self)
                    .flatMap { presenter, userIds -> AnyPublisher<[UserModel?], Never> in
                        presenter.getUsersGoingToClub(usersGoingIds: Array(userIds.keys))
                    }
                    .eraseToAnyPublisher()
        
        let myCurrentClubModelPublisher =
            useCases.userDataUseCase.getUserInfo(uid: myUid)
                .map({ $0?.attendingClub })
                .withUnretained(self)
                .flatMap { presenter, attendingClubId -> AnyPublisher<CompanyModel?, Never> in
                    if let attendingClubId = attendingClubId {
                        return presenter.useCases.companyDataUseCase.getCompanyInfo(uid: attendingClubId)
                    } else {
                        return Just(nil)
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        
        input
            .viewDidLoad
            .handleEvents(receiveRequest: { [weak self] _ in
                self?.viewModel.loading = true
            })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                Publishers.CombineLatest3(
                    assistanceObserver,
                    followObserver,
                    myCurrentClubModelPublisher
                )
            })
            .withUnretained(self)
            .sink { data in
                
                let presenter = data.0
                let usersGoingToClub = data.1.0
                let followingPeople = data.1.1?.following ?? [:]
                let myCurrentClubModel = data.1.2
                
                presenter.viewModel.loading = false
                
                let myUserFollowsThisProfile = followingPeople.first(where: { $0.key == presenter.model.profileId }) != nil
                presenter.viewModel.followButtonType = myUserFollowsThisProfile ? .following : .follow
                
                presenter.viewModel.followingPeopleGoingToClub = usersGoingToClub.compactMap({ $0 }).filter({ userGoing in
                    followingPeople.contains(where: {  $0.key == userGoing.uid })
                })
                
                presenter.viewModel.usersGoingToClub = usersGoingToClub.compactMap({ $0 })
                presenter.viewModel.imGoingToClub = usersGoingToClub.contains(where: { $0?.uid == presenter.myUid }) ? .going : .notGoing
                
                if presenter.viewModel.imGoingToClub == .going, let clubName = myCurrentClubModel?.username {
                    presenter.sendNotificationToFollowersIfNeeded(clubName: clubName)
                }
                
                presenter.viewModel.myCurrentClubModel = myCurrentClubModel
               
            }
            .store(in: &cancellables)
    }
    
    private func getUsersGoingToClub(usersGoingIds: [String]) -> AnyPublisher<[UserModel?], Never> {
        
        let publishers: [AnyPublisher<UserModel?, Never>] = usersGoingIds.map { id in
            useCases.userDataUseCase.getUserInfo(uid: id)
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    func listenToInputs(input: UserProfilePresenterImpl.ViewInputs) {

        input
            .followProfile
            .withUnretained(self)
            .sink { presenter, _ in
                
            }
            .store(in: &cancellables)
        
        input
            .goToClub
            .withUnretained(self)
            .sink { presenter, _ in
                
            }
            .store(in: &cancellables)
        
        input
            .goBack
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goBack()
            }
            .store(in: &cancellables)
        
        input
            .onUserSelected
            .withUnretained(self)
            .sink { presenter, _ in
                
            }
            .store(in: &cancellables)
    }
    
    
}

private extension UserProfilePresenterImpl {
    
    private func sendNotificationToFollowersIfNeeded(clubName: String) {
        print("sendNotificationToFollowersIfNeeded: Checking if user is attending club...")
        
        if self.viewModel.imGoingToClub == .going {
            useCases.noficationsUsecase.sendNotificationToFollowers(clubName: clubName)
        }
    }
    
    private func addUserNotification() {
        let model = NotificationModel(
            ispost: false,
            postid: "",
            text: GlobalStrings.shared.startFollowUserText,
            userid: myUid
        )
        
        useCases.noficationsUsecase.addNotification(
            model: model,
            publisherId: self.model.profileId
        )
        .sink { sent in
            if sent {
                print("notification user with uid \(self.model.profileId) started following you")
            } else {
                print("notification user not sent")
            }
        }
        .store(in: &cancellables)
    }

    
    // NEEDED??
//    private func getCompanyInfo() -> CompanyModel? {
        //        if model.isCompanyProfile {
        //            viewModel.currentClubModel = UserDefaults.getCompanies()?.users.values.first(where: { $0.uid == model.profileId })
        //        }
//    }
    
    
}

//si das al vaso --> confirmas que vas al club, else --> no attending
//lista de usuarios que van a la discoteca
// lista de usuarios que van a la discoteca que son tus amigos

//No empresa
// foto, nombre de perfil, following
