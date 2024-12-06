import SwiftUI
import Combine


enum NotificationType {
    case friendRequest
    case typedefault
}

final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationModelForView] = []
    @Published var loading: Bool = false
    @Published var headerError: ErrorState?
}

protocol NotificationsPresenter {
    var viewModel: NotificationsViewModel { get }
    func transform(input: NotificationsPresenterImpl.ViewInputs)
}

final class NotificationsPresenterImpl: NotificationsPresenter {
    
    struct UseCases {
        let notificationsUseCase: NotificationsUseCase
        let userDataUseCase: UserDataUseCase
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let accept: AnyPublisher<String, Never>
        let reject: AnyPublisher<String, Never>
    }
    
    var viewModel: NotificationsViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = NotificationsViewModel()
    }
    
    func transform(input: NotificationsPresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .performRequest(request: { presenter , _  -> AnyPublisher<[String: NotificationModel], Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just([:]).eraseToAnyPublisher()
                }
                return presenter.useCases.notificationsUseCase.fetchNotifications(publisherId: uid)
                
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { _ in })
            .withUnretained(self)
            .flatMap({ presenter, notificationsModel ->  AnyPublisher<[NotificationModelForView], Never> in
                
                let publishers: [AnyPublisher<NotificationModelForView, Never>] = notificationsModel.values.map { model in

                    if let companyFound = UserDefaults.getCompanies()?.users.values.first(where: { $0.uid == model.userId }) {
                        presenter.getNotificationFromCompany(model: model, companyFound: companyFound)
                    } else {
                        presenter.getNotificationFromUser(model: model)
                    }
                }
                
                return Publishers.MergeMany(publishers)
                    .collect()
                    .eraseToAnyPublisher()
                
            })
            .withUnretained(self)
            .sink { presenter, notifications in
                presenter.viewModel.notifications = notifications
            }
            .store(in: &cancellables)
    }
    
//    func acceptFollowRequest(requesterUid: String) {
//        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
//        
//        // El solicitante sigue al usuario actual
//        let followRef = Database.database().reference().child("Follow").child(currentUserId).child("Followers").child(requesterUid)
//        followRef.setValue(true) { error, _ in
//            if error == nil {
//                // El usuario actual sigue al solicitante
//                let reverseFollowRef = Database.database().reference().child("Follow").child(requesterUid).child("Following").child(currentUserId)
//                reverseFollowRef.setValue(true) { error, _ in
//                    if error == nil {
//                        self.removePendingRequest(requesterUid: requesterUid, currentUserId: currentUserId)
//                    }
//                }
//            }
//        }
//    }
}


private extension NotificationsPresenterImpl {
    
    func getNotificationFromCompany(model: NotificationModel, companyFound: CompanyModel) -> AnyPublisher<NotificationModelForView, Never> {
        let modelView = NotificationModelForView(
            isPost: model.ispost,
            text: model.text,
            userName: companyFound.username ?? "Unknown",
            type: model.text == "Solicitud de seguimiento" ? .friendRequest : .typedefault,
            profileImage: companyFound.imageUrl,
            postImage: nil,
            userId: model.userId,
            postId: model.postId
        )
        
        return Just(modelView)
            .eraseToAnyPublisher()
    }
    
    func getNotificationFromUser(model: NotificationModel) -> AnyPublisher<NotificationModelForView, Never> {
        return useCases.userDataUseCase.getUserInfo(uid: model.userId)
            .map { userModel in
                let modelView = NotificationModelForView(
                    isPost: model.ispost,
                    text: model.text,
                    userName: userModel?.username ?? "Unknown",
                    type: model.text == "Solicitud de seguimiento" ? .friendRequest : .typedefault,
                    profileImage: userModel?.image,
                    postImage: nil,
                    userId: model.userId,
                    postId: model.postId
                )
                
                return modelView
            }
            .eraseToAnyPublisher()
    }
}

//class NotificationAdapter: ObservableObject {
//    @Published var notifications: [NotificationModel] = []
//    
//    private var dbRef: DatabaseReference!
//    
//    init() {
//        self.dbRef = Database.database().reference().child("Notifications")
//        readNotifications()
//    }
//    
//    // Función para aceptar solicitud de seguimiento
//    func acceptFollowRequest(requesterUid: String) {
//        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
//        
//        // El solicitante sigue al usuario actual
//        let followRef = Database.database().reference().child("Follow").child(currentUserId).child("Followers").child(requesterUid)
//        followRef.setValue(true) { error, _ in
//            if error == nil {
//                // El usuario actual sigue al solicitante
//                let reverseFollowRef = Database.database().reference().child("Follow").child(requesterUid).child("Following").child(currentUserId)
//                reverseFollowRef.setValue(true) { error, _ in
//                    if error == nil {
//                        self.removePendingRequest(requesterUid: requesterUid, currentUserId: currentUserId)
//                    }
//                }
//            }
//        }
//    }
//    
//    func rejectFollowRequest(requesterUid: String) {
//        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
//        
//        // Eliminar solicitud pendiente
//        removePendingRequest(requesterUid: requesterUid, currentUserId: currentUserId)
//    }
//    
//    // Eliminar la solicitud pendiente de seguimiento
//    private func removePendingRequest(requesterUid: String, currentUserId: String) {
//        let pendingRef = Database.database().reference().child("Follow").child(currentUserId).child("Pending").child(requesterUid)
//        pendingRef.removeValue()
//    }
//    
//    // Función para eliminar notificación de Firebase
//    func removeNotificationFromFirebase(requesterUid: String) {
//        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
//        
//        let notificationRef = Database.database().reference().child("Notifications").child(currentUserId)
//        notificationRef.observeSingleEvent(of: .value) { snapshot in
//            for child in snapshot.children {
//                if let childSnapshot = child as? DataSnapshot,
//                   let notification = childSnapshot.value as? [String: Any],
//                   let notificationUserId = notification["userId"] as? String,
//                   notificationUserId == requesterUid,
//                   notification["text"] as? String == "Solicitud de seguimiento" {
//                    childSnapshot.ref.removeValue()
//                    break
//                }
//            }
//        }
//    }
//    
//}
//
//
//struct PostImageView: View {
//    var postId: String
//    
//    var body: some View {
//        WebImage(url: URL(string: "https://example.com/postImage/\(postId)"))
//            .resizable()
//            .scaledToFit()
//            .frame(width: 100, height: 100)
//            .placeholder {
//                ProgressView()
//            }
//    }
//}
//
//struct ProfileImageView: View {
//    var userId: String
//    
//    var body: some View {
//        WebImage(url: URL(string: "https://example.com/profileImage/\(userId)"))
//            .resizable()
//            .scaledToFit()
//            .frame(width: 50, height: 50)
//            .clipShape(Circle())
//            .placeholder {
//                ProgressView()
//            }
//    }
//}
