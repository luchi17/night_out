import SwiftUI
import Combine

//From Maps when tapping on marker

final class PrivateUserProfileViewModel: ObservableObject {

    @Published var buttonTitle: String = ""
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
}

protocol PrivateUserProfilePresenter {
    var viewModel: PrivateUserProfileViewModel { get }
    func transform(input: PrivateUserProfilePresenterImpl.ViewInputs)
}

final class PrivateUserProfilePresenterImpl: PrivateUserProfilePresenter {
    
    struct UseCases {
        let followUseCase: FollowUseCase
        let noficationsUsecase: NotificationsUseCase
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let requestProfile: AnyPublisher<Void, Never>
    }
    
    var viewModel: PrivateUserProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private var model: ProfileModel
    
    let myUid = FirebaseServiceImpl.shared.getCurrentUserUid() ?? ""
    let requestedTitle = "Solicitud enviada".uppercased()
    let toRequestTitle = "Enviar solicitud".uppercased()
    
    init(
        useCases: UseCases,
        actions: Actions,
        model: ProfileModel
    ) {
        self.actions = actions
        self.useCases = useCases
        self.model = model
        
        viewModel = PrivateUserProfileViewModel()
    }
    
    func transform(input: PrivateUserProfilePresenterImpl.ViewInputs) {
        
        listenToInputs(input: input)
        
        input
            .viewDidLoad
            .handleEvents(receiveRequest: { [weak self] _ in
                self?.viewModel.loading = true
            })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.followUseCase.fetchFollow(id: presenter.myUid)
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .sink { presenter, followModel in
                
                presenter.viewModel.loading = false
                
                let myUserFollowsThisProfile = followModel?.following?.first(where: { $0.key == presenter.model.profileId }) != nil
                
                if !myUserFollowsThisProfile {
                    presenter.viewModel.buttonTitle = presenter.toRequestTitle
                } else { //Pending
                    presenter.viewModel.buttonTitle = presenter.requestedTitle
                }
              
            }
            .store(in: &cancellables)
    }
    
    func listenToInputs(input: PrivateUserProfilePresenterImpl.ViewInputs) {
        
        input
            .requestProfile
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.requestProfileTapped()
            }
            .store(in: &cancellables)
    }
}

private extension PrivateUserProfilePresenterImpl {
    
    private func addUserRequestFollowNotification() {
        let model = NotificationModel(
            ispost: false,
            postid: "",
            text: "\(GlobalStrings.shared.followUserText)",
            userid: myUid,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
        
        useCases.noficationsUsecase.addNotification(
            model: model,
            publisherId: self.model.profileId
        )
        .sink { sent in
            if sent {
                print("notification user with uid \(self.model.profileId) request follow")
            } else {
                print("notification request follow not sent")
            }
        }
        .store(in: &cancellables)
    }
    
    private func removeUserRequestFollowNotification() {
        useCases
            .noficationsUsecase
            .fetchNotifications(publisherId: model.profileId)
            .withUnretained(self)
            .sink(receiveValue: { presenter, notifications in
                let matchingNotification = notifications.first { notificationDict in
                    notificationDict.value.userid == presenter.myUid && notificationDict.value.text == "\(GlobalStrings.shared.followUserText)"
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
    }

    private func requestProfileTapped() {
        if viewModel.buttonTitle == requestedTitle {
            print("Eliminar la solicitud de Pending")
            useCases.followUseCase.removePending(otherUid: model.profileId)
            removeUserRequestFollowNotification()
            viewModel.buttonTitle = toRequestTitle
        } else {
            print("Solicitar")
            useCases.followUseCase.addPendingRequest(otherUid: model.profileId)
            addUserRequestFollowNotification()
            viewModel.buttonTitle = requestedTitle
        }
        
    }
}
