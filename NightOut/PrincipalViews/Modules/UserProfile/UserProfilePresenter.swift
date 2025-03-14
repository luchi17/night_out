import SwiftUI
import Combine
import Firebase

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
                    .frame(width: 50, height: 50)
            case .notGoing:
                Image("whisky_empty")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
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

    @Published var isCompanyProfile: Bool
    
    @Published var loading: Bool = false
    @Published var showGenderAlert: Bool = false
    @Published var toast: ToastType?
    
    @Published var myUserModel: UserModel?
    
    @Published var images: [IdentifiableImage] = []
    
    var alreadyAttendingClub: String?
    var hasEntryToday: Bool = false
    
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
        let openConfig: VoidClosure
        let openDiscoDetail: InputClosure<CompanyModel>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let followProfile: AnyPublisher<Void, Never>
        let goToClub: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
        let onUserSelected: AnyPublisher<UserGoingCellModel, Never>
        let openConfig: AnyPublisher<Void, Never>
        let openDiscoDetail: AnyPublisher<Void, Never>
    }
    
    var viewModel: UserProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private var model: ProfileModel
    
    let myUid = FirebaseServiceImpl.shared.getCurrentUserUid() ?? ""
    let currentDateString: String?
    
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        currentDateString = dateFormatter.string(from: Date())
    }
    
    func transform(input: UserProfilePresenterImpl.ViewInputs) {
        
        listenToInputs(input: input)
        
        let myFollowObserver =
        useCases.followUseCase
            .observeFollow(id: myUid)
            .map({
                let following = $0?.following ?? [:]
                let keys = following.keys
                return Array(keys)
            })
            .withUnretained(self)
            .flatMap { presenter, followingList in
                presenter.filterUsersAttendingClub(followingList)
            }
            .eraseToAnyPublisher()
        
        //Just for companies
        let assistanceObserver =
        observeClubAssistance()
            .withUnretained(self)
            .flatMap { presenter, userIds -> AnyPublisher<[UserModel?], Never> in
                presenter.getInfoOfUsersGoingToClub(usersGoingIds: userIds)
            }
            .eraseToAnyPublisher()
        
        let myUserModel =
        useCases.userDataUseCase.getUserInfo(uid: myUid)
        
        input
            .viewDidLoad
            .filter({ [weak self] _ in  self?.model.isCompanyProfile ?? false })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.postsUseCase.fetchPosts()
                    .map { posts in
                        let matchingPosts = posts.filter { post in
                            return post.value.publisherId == presenter.model.profileId
                        }.values
                        return Array(matchingPosts)
                    }
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .flatMap { presenter, posts in
                let publishers: [AnyPublisher<IdentifiableImage, Never>] = posts.map { post in
                    
                    presenter.getPostImagePublisher(image: post.postImage)
                        .compactMap({ $0 })
                        .map({ IdentifiableImage(image: $0 )})
                        .eraseToAnyPublisher()
                }
                return Publishers.MergeMany(publishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink { presenter, images in
                presenter.viewModel.images = images
            }
            .store(in: &cancellables)
        
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
                    myUserModel
                )
            })
            .withUnretained(self)
            .sink { presenter, data in
                let usersGoingToClub = data.0
                let followingPeople = data.1
                let myUserModel = data.2
                
                presenter.viewModel.loading = false
                
                presenter.viewModel.myUserModel = myUserModel
                
                let myUserFollowsThisProfile = followingPeople.first(where: { $0.uid == presenter.model.profileId }) != nil
                presenter.viewModel.followButtonType = myUserFollowsThisProfile ? .following : .follow
                
                presenter.viewModel.followingPeopleGoingToClub = followingPeople.map({ $0.toUserGoingCellModel() })
                
                presenter.viewModel.usersGoingToClub = usersGoingToClub.compactMap({ $0 }).map({ $0.toUserGoingCellModel() })
                presenter.viewModel.imGoingToClub = usersGoingToClub.contains(where: { $0?.uid == presenter.myUid }) ? .going : .notGoing
                
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
            .openDiscoDetail
            .withUnretained(self)
            .sink { presenter, _ in
                if let club = UserDefaults.getCompanies()?.users.first(where: { $0.key == presenter.model.profileId })?.value {
                    presenter.actions.openDiscoDetail(club)
                }
            }
            .store(in: &cancellables)
        
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
                presenter.checkClubAttendance(profileId: presenter.model.profileId)
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
            .openConfig
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.openConfig()
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

    private func addUserFollowNotification() {
        let model = NotificationModel(
            ispost: false,
            postid: "",
            text: "\(self.viewModel.myUserModel?.username ?? "Desconocido") \(GlobalStrings.shared.startFollowUserText)",
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
                    notificationDict.value.userid == presenter.myUid && notificationDict.value.text.contains("\(GlobalStrings.shared.startFollowUserText)")
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
    
    func checkClubAttendance(profileId: String) {
        let clubsRef = FirebaseServiceImpl.shared.getClub()
        
//        observe(.value)
        clubsRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            
            guard let self = self else { return }
            
            viewModel.alreadyAttendingClub = nil
            viewModel.hasEntryToday = false
            
            for clubSnapshot in snapshot.children {
                
                guard let clubSnapshot = clubSnapshot as? DataSnapshot else {
                    continue
                }
                
                let assistanceDateRef = clubSnapshot.childSnapshot(forPath: "Assistance")
                
                for dateSnapshot in assistanceDateRef.children {
                    
                    guard let dateSnapshot = dateSnapshot as? DataSnapshot else { continue }
                    
                    if dateSnapshot.key == self.currentDateString {  // 🔹 Evento es de hoy
                        
                        let userRef = dateSnapshot.childSnapshot(forPath: self.myUid)
                        
                        let hasEntry = userRef.childSnapshot(forPath: "entry").value as? Bool ?? false
                        
                        if !hasEntry {
                            self.viewModel.alreadyAttendingClub = clubSnapshot.key
                            break
                        } else {
                            self.viewModel.hasEntryToday = true
                        }
                    }
                }
            }
            
            if let alreadyAttendingClub = self.viewModel.alreadyAttendingClub, alreadyAttendingClub == profileId {
                // 🔹 Verificar si el usuario realmente está en el club antes de eliminarlo
                self.checkUserInClub(profileId: profileId, currentDate: self.currentDateString!)
                
            } else if self.viewModel.alreadyAttendingClub != nil && !self.viewModel.hasEntryToday {
                // 🔹 Ya está asistiendo a otro club HOY sin "entry = true" → No se le permite cambiar
                
                let companyName = UserDefaults.getCompanies()?.users.first(where: { $0.key == self.viewModel.alreadyAttendingClub })?.value.username
                
                DispatchQueue.main.async {
                    self.viewModel.toast = .custom(.init(
                        title: "Asistencia Actual",
                        description: "Ya estás asistiendo a \(companyName ?? "otro club"). Cancela la asistencia antes de asistir a otro evento.",
                        image: nil
                    ))
                }
            } else {
                // 🔹 Si el usuario NO está asistiendo a ningún club o tiene "entry = true" en otro → Permitir asistencia
                self.registerUserInClub(profileId: profileId, currentDate: self.currentDateString!)
            }
        }
    }
    
    private func checkUserInClub(profileId: String, currentDate: String) {
        let userInClubRef = FirebaseServiceImpl.shared.getClub().child(self.model.profileId).child("Assistance").child(self.currentDateString!)
            .child(myUid)
        
        userInClubRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            if snapshot.exists() {
                self?.removeUserFromClub(profileId: profileId, currentDate: currentDate)
            } else {
                self?.registerUserInClub(profileId: profileId, currentDate: currentDate)
            }
        }
    }
    
    private func registerUserInClub(profileId: String, currentDate: String) {
        let assistanceRef = FirebaseServiceImpl.shared.getClub().child(self.model.profileId).child("Assistance").child(self.currentDateString!)
        
        let attendingClubRef = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: myUid).child("attendingClub")
        
        let userMap: [String: Any] = [
            "uid": myUid,
            "gender": viewModel.myUserModel?.gender ?? ""
        ]
        
        assistanceRef.child(myUid).setValue(userMap) { error, _ in
            if let error = error {
                print("Error registering user in club: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.viewModel.toast = .custom(.init(
                        title: "Error",
                        description: "Error al procesar la solicitud.",
                        image: nil
                    ))
                }
            } else {
                attendingClubRef.setValue(profileId)
                // Update UI, like the button state
                print("User registered in club")
                self.useCases.noficationsUsecase.sendNotificationToFollowers(
                    myName: self.viewModel.myUserModel?.username ?? "Desconocido",
                    clubName: self.model.fullname ?? "Sitio desconocido"
                )
            }
        }
    }
    
    private func removeUserFromClub(profileId: String, currentDate: String) {
        let assistanceRef = FirebaseServiceImpl.shared.getClub().child(self.model.profileId).child("Assistance").child(self.currentDateString!)
            .child(myUid)
        
        let attendingClubRef = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: myUid).child("attendingClub")
        assistanceRef.removeValue { error, _ in
            if let error = error {
                print("Error removing user from club: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.viewModel.toast = .custom(.init(
                        title: "Error",
                        description: "Error al procesar la solicitud.",
                        image: nil
                    ))
                }

            } else {
                attendingClubRef.removeValue()
                // Update UI, like the button state
                print("User removed from club")
                DispatchQueue.main.async {
                    self.viewModel.toast = .custom(
                        .init(
                            title: "Has dejado de asistir a este club",
                            description: nil,
                            image: nil,
                            backgroundColor: .green
                        ))
                }
            }
        }
    }
    
    func observeClubAssistance() -> AnyPublisher<[String], Never> {
        
        let clubRef = FirebaseServiceImpl.shared.getClub().child(self.model.profileId).child("Assistance").child(self.currentDateString!)
        
        let subject = PassthroughSubject<[String], Never>()
        
        clubRef.observe(.value) { snapshot in
            let clubAttendees = Array(snapshot.children.compactMap { ($0 as? DataSnapshot)?.key } )
            
            print("clubAttendees \(clubAttendees)")
            
            subject.send(clubAttendees)
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    private func filterUsersAttendingClub(_ followingList: [String]) -> AnyPublisher<[UserModel], Never> {
        
        let publishers = followingList.map { userId in
            self.checkUserAttendance(userId, currentDate: self.currentDateString!)
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { $0.compactMap { $0 } }
            .eraseToAnyPublisher()
    }
    
    private func checkUserAttendance(_ userId: String, currentDate: String) -> AnyPublisher<UserModel?, Never> {
        
        let userClubAssistanceRef = FirebaseServiceImpl.shared.getClub().child(self.model.profileId).child("Assistance").child(self.currentDateString!).child(userId)
        
        return Future<UserModel?, Never> { promise in
            
            userClubAssistanceRef.observeSingleEvent(of: .value) { snapshot in
                
                if snapshot.exists() {
                    // El usuario está asistiendo al club hoy, agrégalo a la lista
                    self.useCases.userDataUseCase.getUserInfo(uid: userId)
                        .sink { userModel in
                            if let userModel = userModel {
                                promise(.success(userModel))
                            } else {
                                promise(.success(nil))
                            }
                        }
                        .store(in: &self.cancellables)
                } else {
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
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
