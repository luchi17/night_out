import SwiftUI
import Combine


struct ProfileModel: Hashable, Identifiable {
    var profileImageUrl: String?
    var username: String?
    var fullname: String?
    var profileId: String
    var isCompanyProfile: Bool
    var isPrivateProfile: Bool
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(profileId)
    }
    
    static func == (lhs: ProfileModel, rhs: ProfileModel) -> Bool {
        return lhs.profileId == rhs.profileId
    }
    
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
    
    var whiskyImage: some View {
        Group {
            switch self {
            case .going:
                Image("whisky_full")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            case .notGoing:
                Image("whisky_empty")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white)
            }
        }
    }
}

//From Maps when tapping on marker

final class UserProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = ""
    @Published var fullname: String = ""
    @Published var followButtonType: FollowButtonType?
    
    @Published var imGoingToClub: ImGoingToClub = .notGoing
    @Published var usersGoingToClub: [UserGoingCellModel] = []
    @Published var followingPeopleGoingToClub: [UserGoingCellModel] = []
    
    @Published var myCurrentClubModel: CompanyModel?
    @Published var isCompanyProfile: Bool
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var myUserModel: UserModel?
    
//    @Published var images: [IdentifiableImage] = []
    
    
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
        let postsUseCase: PostsUseCase
    }
    
    struct Actions {
        let goBack: VoidClosure
        let openAnotherProfile: InputClosure<ProfileModel>
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
        
        let myFollowObserver =
        useCases.followUseCase.observeFollow(id: myUid)
            .eraseToAnyPublisher()
        
        //Just for companies
        let assistanceObserver =
        useCases.clubUseCase.observeAssistance(profileId: self.model.profileId)
            .withUnretained(self)
            .flatMap { presenter, userIds -> AnyPublisher<[UserModel?], Never> in
                presenter.getInfoOfUsersGoingToClub(usersGoingIds: Array(userIds.keys))
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
        
        //Post when
//        input
//            .viewDidLoad
//            .filter({ [weak self] _ in  self?.model.isCompanyProfile ?? false })
//            .withUnretained(self)
//            .flatMap({ presenter, _ in
//                presenter.useCases.postsUseCase.fetchPosts()
//                    .map { posts in
//                        let matchingPosts = posts.filter { post in
//                            return post.value.publisherId == presenter.model.profileId
//                        }.values
//                        return Array(matchingPosts)
//                    }
//                    .eraseToAnyPublisher()
//            })
//            .withUnretained(self)
//            .flatMap { presenter, posts in
//                let publishers: [AnyPublisher<IdentifiableImage, Never>] = posts.map { post in
//                    
//                    presenter.getPostImagePublisher(image: post.postImage)
//                        .compactMap({ $0 })
//                        .map({ IdentifiableImage(image: $0 )})
//                        .eraseToAnyPublisher()
//                }
//                return Publishers.MergeMany(publishers)
//                    .collect()
//                    .eraseToAnyPublisher()
//            }
//            .withUnretained(self)
//            .sink { presenter, images in
//                presenter.viewModel.images = images
//            }
//            .store(in: &cancellables)
        
        input
            .viewDidLoad
            .handleEvents(receiveRequest: { [weak self] _ in
                self?.viewModel.loading = true
            })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                Publishers.CombineLatest3(
                    assistanceObserver,
                    myFollowObserver,
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
                
                presenter.viewModel.followingPeopleGoingToClub = usersGoingToClub.compactMap({ $0 })
                    .filter({ userGoing in
                        followingPeople.contains(where: { $0.key == userGoing.uid })
                    })
                    .map({ $0.toUserGoingCellModel() })
                
                presenter.viewModel.usersGoingToClub = usersGoingToClub.compactMap({ $0 }).map({ $0.toUserGoingCellModel() })
                
                presenter.viewModel.imGoingToClub = usersGoingToClub.contains(where: { $0?.uid == presenter.myUid }) ? .going : .notGoing
                presenter.viewModel.myUserModel = usersGoingToClub.compactMap({ $0 }).first(where: { $0.uid == presenter.myUid })
                
                presenter.viewModel.myCurrentClubModel = myCurrentClubModel
                
            }
            .store(in: &cancellables)
    }
    
    private func getInfoOfUsersGoingToClub(usersGoingIds: [String]) -> AnyPublisher<[UserModel?], Never> {
        
        let publishers: [AnyPublisher<UserModel?, Never>] = usersGoingIds.map { id in
            useCases.userDataUseCase.getUserInfo(uid: id)
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    private func getPostImagePublisher(image: String?) -> AnyPublisher<UIImage?, Never> {
        if let image = image, let url = URL(string: image) {
            return KingFisherImage.fetchImagePublisher(url: url)
        }
        
        return Just(nil).eraseToAnyPublisher()
    }
    
    func listenToInputs(input: UserProfilePresenterImpl.ViewInputs) {
        
        input
            .followProfile
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.followButtonTapped()
            }
            .store(in: &cancellables)
        
        input
            .goToClub
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.whiskyButtonTapped()
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
            .flatMap({ presenter, userGoingModel in
                presenter.useCases.userDataUseCase.getUserInfo(uid: userGoingModel.id)
                    .compactMap({ $0 })
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .sink { presenter, userModel in
                let profileModel = ProfileModel(
                    profileImageUrl: userModel.image,
                    username: userModel.username,
                    fullname: userModel.fullname,
                    profileId: userModel.uid,
                    isCompanyProfile: false,
                    isPrivateProfile: userModel.profileType == .privateProfile
                )
                presenter.actions.openAnotherProfile(profileModel)
            }
            .store(in: &cancellables)
    }
    
    
}

private extension UserProfilePresenterImpl {
    
    //addNotification()
    private func addUserFollowNotification() {
        let model = NotificationModel(
            ispost: false,
            postid: "",
            text: "\(GlobalStrings.shared.startFollowUserText)",
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
    
    private func followButtonTapped() {
        switch viewModel.followButtonType {
        case .follow:
            // Añadir al seguimiento en "Follow"
            useCases.followUseCase.addFollow(
                requesterProfileUid: myUid,
                profileUid: model.profileId,
                needRemoveFromPending: false
            )
            .withUnretained(self)
            .sink { presenter, followOk in
#warning("DO notificationManager")
                // Enviar notificación
                // notificationManager.getUsernamesAndSendNotification(it1.toString(), profileId)
                
                if followOk {
                    presenter.addUserFollowNotification()
                    print("started following \(presenter.model.profileId)")
                } else {
                    print("Error: started following \(presenter.model.profileId)")
                }
            }
            .store(in: &cancellables)
            
        case .following:
            // Eliminar del seguimiento en "Follow"
            useCases.followUseCase.removeFollow(
                requesterProfileUid: myUid,
                profileUid: model.profileId
            )
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases
                    .noficationsUsecase
                    .fetchNotifications(publisherId: presenter.model.profileId)
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .sink(receiveValue: { presenter, notifications in
                
                let matchingNotification = notifications.first { notificationDict in
                    notificationDict.value.userid == presenter.myUid && notificationDict.value.text == "\(GlobalStrings.shared.startFollowUserText)"
                }
                
                guard let matchingNotification = matchingNotification else {
                    return
                }
                
                presenter.useCases.noficationsUsecase.removeNotification(
                    userId: presenter.model.profileId,
                    notificationId: matchingNotification.key
                )
            })
            .store(in: &cancellables)
            
        default:
            break
        }
    }
    
    private func whiskyButtonTapped() {
        switch viewModel.imGoingToClub {
        case .going:
            //Ya no quiero seguir asistiendo
            useCases.clubUseCase.removeAssistingToClub(clubId: model.profileId)
                .withUnretained(self)
                .sink { presenter, ok in
                    if ok {
                        presenter.viewModel.toast = .custom(
                            .init(
                                title: "Has dejado de asistir a este club",
                                description: nil,
                                image: nil,
                                backgroundColor: .green
                            ))
                    } else {
                        presenter.viewModel.toast = .custom(.init(
                            title: "Error",
                            description: "Error al procesar la solicitud.",
                            image: nil
                        ))
                    }
                }
                .store(in: &cancellables)
            
        case .notGoing:
            //Quiero asistir al club
            if let myCurrentClub = viewModel.myCurrentClubModel, myCurrentClub.uid != model.profileId {  //Pero ya estoy asistiendo a otro
                viewModel.toast = .custom(.init(
                    title: "Asistencia Actual",
                    description: "Ya estás asistiendo a \(myCurrentClub.username ?? "otro club"). Cancela la asistencia antes de asistir a otro evento.",
                    image: nil
                ))
            } else {
                let clubAssistance = ClubAssistance(
                    uid: myUid,
                    gender: viewModel.myUserModel?.gender,
                    tinderPhoto: nil,
                    social: viewModel.myUserModel?.social
                )
                useCases.clubUseCase.addAssistingToClub(
                    clubId: model.profileId,
                    clubAssistance: clubAssistance
                )
                .withUnretained(self)
                .sink { presenter, ok in
                    if ok {
                        presenter.useCases.noficationsUsecase.sendNotificationToFollowers(clubName: presenter.model.profileId)
                    } else {
                        presenter.viewModel.toast = .custom(.init(
                            title: "Error",
                            description: "Error al procesar la solicitud.",
                            image: nil
                        ))
                    }
                }
                .store(in: &cancellables)
            }
        }
    }
}

private extension UserModel {
    func toUserGoingCellModel() -> UserGoingCellModel {
        UserGoingCellModel(
            id: self.uid,
            username: self.username,
            profileImageUrl: self.image
        )
    }
}
