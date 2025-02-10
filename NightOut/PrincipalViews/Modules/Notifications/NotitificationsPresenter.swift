import SwiftUI
import Combine


enum NotificationType {
    case friendRequest
    case typedefault
}

final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationModelForView] = []
    @Published var loading: Bool = false
    @Published var toast: ToastType?
}

protocol NotificationsPresenter {
    var viewModel: NotificationsViewModel { get }
    func transform(input: NotificationsPresenterImpl.ViewInputs)
}

final class NotificationsPresenterImpl: NotificationsPresenter {
    
    struct UseCases {
        let notificationsUseCase: NotificationsUseCase
        let userDataUseCase: UserDataUseCase
        let followUseCase: FollowUseCase
    }
    
    struct Actions {
        let goToProfile: InputClosure<ProfileModel>
        let goToPrivateProfile: InputClosure<ProfileModel>
        let goToPost: InputClosure<NotificationModelForView>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let accept: AnyPublisher<(String, String), Never>
        let reject: AnyPublisher<(String, String), Never>
        let goToPost: AnyPublisher<NotificationModelForView, Never>
        let goToProfile: AnyPublisher<NotificationModelForView, Never>
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
                return presenter.useCases.notificationsUseCase.observeNotifications(publisherId: uid)
                
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { _ in })
            .withUnretained(self)
            .flatMap({ presenter, notificationsModel ->  AnyPublisher<[NotificationModelForView], Never> in
                
                let publishers: [AnyPublisher<NotificationModelForView, Never>] = notificationsModel.map { data in

                    if let companyFound = UserDefaults.getCompanies()?.users.values.first(where: { $0.uid == data.value.userid }) {
                        presenter.getNotificationFromCompany(notificationId: data.key, model: data.value, companyFound: companyFound)
                    } else {
                        presenter.getNotificationFromUser(notificationId: data.key, model: data.value)
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
        
        input
            .accept
            .withUnretained(self)
            .flatMap { presenter, data in
                let notificationId = data.0
                let requesterUid = data.1
                
                return presenter.useCases.followUseCase.addFollow(
                    requesterProfileUid: requesterUid,
                    profileUid: FirebaseServiceImpl.shared.getCurrentUserUid() ?? "",
                    needRemoveFromPending: true
                )
                    .map { success in
                        (notificationId, success)
                    }
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink(receiveValue: { presenter, data in
                let notificationId = data.0
                let success = data.1
                
                if success {
                    presenter.viewModel.toast = .success(.init(title: "Solicitud aceptada", description: nil, image: nil))
                    presenter.useCases.notificationsUseCase.removeNotification(
                        userId: FirebaseServiceImpl.shared.getCurrentUserUid() ?? "",
                        notificationId: notificationId
                    )
                    presenter.viewModel.notifications = presenter.viewModel.notifications
                        .filter({ $0.notificationId != notificationId })
                   
                } else {
                    presenter.viewModel.toast = ToastType.defaultError
                }
                
            })
            .store(in: &cancellables)
        
        
        input
            .reject
            .withUnretained(self)
            .sink { presenter, data in
                let notificationId = data.0
                let requesterUid = data.1
                
                presenter.useCases.followUseCase.rejectFollowRequest(requesterUid: requesterUid)
                presenter.viewModel.toast = .custom(.init(title: "Solicitud rechazada", description: nil, image: (image: Image(systemName: "xmark"), color: Color.white), backgroundColor: Color.gray))
                presenter.useCases.notificationsUseCase.removeNotification(
                    userId: FirebaseServiceImpl.shared.getCurrentUserUid() ?? "",
                    notificationId: notificationId
                )
                presenter.viewModel.notifications = presenter.viewModel.notifications
                    .filter({ $0.notificationId != notificationId })
               

            }
            .store(in: &cancellables)
        
        
        input
            .goToPost
            .withUnretained(self)
            .sink { presenter, post in
                presenter.actions.goToPost(post)
            }
            .store(in: &cancellables)
        
        
        input
            .goToProfile
            .withUnretained(self)
            .flatMap({ presenter, notification -> AnyPublisher<(FollowModel?, NotificationModelForView), Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just((nil, notification)).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: uid)
                    .map({ ($0, notification) })
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .sink { presenter, data in
                let notificationModel = data.1
                let profileModel = ProfileModel(
                    profileImageUrl: notificationModel.profileImage,
                    username: notificationModel.userName,
                    fullname: notificationModel.fullName,
                    profileId: notificationModel.userId,
                    isCompanyProfile: notificationModel.isFromCompany,
                    isPrivateProfile: notificationModel.isPrivateProfile
                )
                
                let following = data.0?.following?.keys.first(where: { $0 == profileModel.profileId }) != nil
                
                if following {
                    presenter.actions.goToProfile(profileModel)
                } else {
                    if notificationModel.isPrivateProfile {
                        presenter.actions.goToPrivateProfile(profileModel)
                    } else {
                        presenter.actions.goToProfile(profileModel)
                    }
                }
            }
            .store(in: &cancellables)
    }
}


private extension NotificationsPresenterImpl {
    
    func getNotificationFromCompany(notificationId: String, model: NotificationModel, companyFound: CompanyModel) -> AnyPublisher<NotificationModelForView, Never> {
        let modelView = NotificationModelForView(
            isPost: model.ispost,
            text: model.text,
            userName: companyFound.username ?? "Unknown",
            fullName: companyFound.fullname ?? "Unknown",
            type: model.text == GlobalStrings.shared.followUserText ? .friendRequest : .typedefault,
            profileImage: companyFound.imageUrl,
            postImage: nil,
            userId: model.userid,
            postId: model.postid,
            notificationId: notificationId,
            isFromCompany: true,
            isPrivateProfile: companyFound.profileType == .privateProfile
        )
        
        return Just(modelView)
            .eraseToAnyPublisher()
    }
    
    func getNotificationFromUser(notificationId: String, model: NotificationModel) -> AnyPublisher<NotificationModelForView, Never> {
        return useCases.userDataUseCase.getUserInfo(uid: model.userid)
            .map { userModel in
                let modelView = NotificationModelForView(
                    isPost: model.ispost,
                    text: model.text,
                    userName: userModel?.username ?? "Unknown",
                    fullName: userModel?.fullname ?? "Unknown",
                    type: model.text == GlobalStrings.shared.followUserText ? .friendRequest : .typedefault,
                    profileImage: userModel?.image,
                    postImage: nil,
                    userId: model.userid,
                    postId: model.postid,
                    notificationId: notificationId,
                    isFromCompany: false,
                    isPrivateProfile: userModel?.profileType == .privateProfile
                )
                
                return modelView
            }
            .eraseToAnyPublisher()
    }

}
