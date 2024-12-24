import SwiftUI
import Combine

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

final class UserProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = ""
    @Published var fullname: String = ""
    @Published var followButtonType: FollowButtonType?
    @Published var imGoingToClub: ImGoingToClub = .notGoing
    @Published var usersGoingToClub: [UserModel] = []
    @Published var whiskyButtonImage: [UserModel] = []
    
    @Published var loading: Bool = false
    
    
    
    init(profileImageUrl: String?, username: String?, fullname: String?) {
        self.profileImageUrl = profileImageUrl
        self.username = username ?? "Nombre no disponible"
        self.fullname = fullname ?? "Username no disponible"
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
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let followProfile: AnyPublisher<Void, Never>
    }
    
    var viewModel: UserProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private var model: UserModel
    
    init(
        useCases: UseCases,
        actions: Actions,
        model: UserModel
    ) {
        self.actions = actions
        self.useCases = useCases
        self.model = model
        
        
        viewModel = UserProfileViewModel(
            profileImageUrl: model.image,
            username: model.username,
            fullname: model.fullname
        )
    }
    
    func transform(input: UserProfilePresenterImpl.ViewInputs) {
        
        let myUid = FirebaseServiceImpl.shared.getCurrentUserUid() ?? ""
        
        let followObserver =
        self.useCases.followUseCase.observeFollow(id: myUid)
            .withUnretained(self)
            .handleEvents(receiveOutput: { presenter, followModel in
                let myUserFollowsThisProfile = followModel?.following?.first(where: { $0.key == presenter.model.uid }) != nil
                presenter.viewModel.followButtonType = myUserFollowsThisProfile ? .following : .follow
            })
            .map({ $0.1 })
            .eraseToAnyPublisher()
        
        
        let assistanceObserver =
        self.useCases.clubUseCase.observeAssistance(clubProfileId: self.model.uid)
            .withUnretained(self)
            .flatMap { presenter, userIds -> AnyPublisher<[UserModel?], Never> in
                presenter.handleUsersGoingToClub(
                    usersGoingIds: Array(userIds.keys),
                    myUid: myUid
                )
            }
            .withUnretained(self)
            .flatMap { presenter, _ -> AnyPublisher<String?, Never> in
                // Obtener el nombre del club al que el usuario está asistiendo_ #warning("TODO: Check Javi")
                presenter.useCases.clubUseCase.getClubName(clubProfileId: presenter.model.uid)
                    .handleEvents(receiveOutput: { clubName in
                        if presenter.viewModel.imGoingToClub == .going, let clubName = clubName {
                            presenter.sendNotificationToFollowersIfNeeded(clubName: clubName)
                        }
                    })
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        
        
        input
            .viewDidLoad
            .handleEvents(receiveRequest: { [weak self] _ in
                self?.viewModel.loading = true
            })
            .combineLatest(assistanceObserver, followObserver)
            .withUnretained(self)
            .sink { presenter, data in
                let assistance = data.1
                let follow = data.2
                
                //// Actualizar la lista de seguidores y asistencia cuando cambie la asistencia
                // setupFollowingUsersRecyclerView
            }
            .store(in: &cancellables)
        
       
        
        
        
        input
            .followProfile
            .withUnretained(self)
            .sink { presenter, _ in
                    
            }
            .store(in: &cancellables)
    }
    
    
}

private extension UserProfilePresenterImpl {
    private func handleUsersGoingToClub(usersGoingIds: [String], myUid: String) -> AnyPublisher<[UserModel?], Never> {
        
        let publishers: [AnyPublisher<UserModel?, Never>] = usersGoingIds.map { id in
            useCases.userDataUseCase.getUserInfo(uid: id)
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .withUnretained(self)
            .handleEvents(receiveOutput: { presenter, usersGoingToClub in
                presenter.viewModel.usersGoingToClub = usersGoingToClub.compactMap({ $0 })
                presenter.viewModel.imGoingToClub = usersGoingToClub.contains(where: { $0?.uid == myUid }) ? .going : .notGoing
                
            })
            .map({ $0.1 })
            .eraseToAnyPublisher()
    }
    
    private func sendNotificationToFollowersIfNeeded(clubName: String) {
        print("sendNotificationToFollowersIfNeeded: Checking if user is attending club...")
        
        if self.viewModel.imGoingToClub == .going {
            useCases.noficationsUsecase.sendNotificationToFollowers(clubName: clubName)
        }
    }
}

//        input
//            .viewDidLoad
//            .withUnretained(self)
//            .handleEvents(receiveRequest: { [weak self] _ in
//                self?.viewModel.loading = true
//            })
//            .flatMap({ presenter, _ -> AnyPublisher<[String], Never> in
//                return presenter.useCases.clubUseCase.getAssistance(clubProfileId: presenter.model.uid)
//                    .map({ Array($0.keys) }) //Returning ids of Assistance
//                    .eraseToAnyPublisher()
//            })
//            .withUnretained(self)
//            .flatMap { presenter, userIds -> AnyPublisher<[model?], Never> in
//                presenter.getInfoOfUsersGoingToClub(usersGoingIds: Array(userIds))
//            }
//            .withUnretained(self)
//            .flatMap { presenter, userIds -> AnyPublisher<[model?], Never> in
//                presenter.useCases.clubUseCase.getClubName(clubProfileId: presenter.)
//            }
