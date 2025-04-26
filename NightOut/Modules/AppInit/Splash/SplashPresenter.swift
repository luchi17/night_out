import Combine
import SwiftUI
import FirebaseMessaging

class SplashViewModel: ObservableObject {
    
    enum State: Equatable {
        case idle
        case isInvalidVersion
        case isJailBreak
    }

    @Published var state: State
    @Published var isLoading: Bool
    @Published var isShowingErrorAlert: Bool
    
    init(
        state: State,
        isLoading: Bool,
        isShowingErrorAlert: Bool
    ) {
        self.state = state
        self.isLoading = isLoading
        self.isShowingErrorAlert = isShowingErrorAlert
    }
}

protocol SplashPresenter {
    var viewModel: SplashViewModel { get }
    func transform(input: SplashPresenterImpl.Input)
}

final class SplashPresenterImpl: SplashPresenter {
    var viewModel: SplashViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
    }
    
    struct Actions {
        let onMainFlow: VoidClosure
        let onLogin: VoidClosure
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases) {
        self.viewModel = SplashViewModel(
            state: .idle,
            isLoading: false,
            isShowingErrorAlert: false
        )
        self.actions = actions
        self.useCases = useCases
    }
    
    func transform(input: Input) {
       
        input.viewIsLoaded
            .withUnretained(self)
            .sink { [weak self] _ in
                if FirebaseServiceImpl.shared.getIsLoggedin() {
                    #warning("TODO: quitar comentario cuando cuenta empresa creada.")
                    // self?.updateFCMToken()
                    self?.actions.onMainFlow()
                } else {
                    self?.actions.onLogin()
                }
            }
            .store(in: &cancellables)
    }
    
    func updateFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error al obtener el token de FCM: \(error.localizedDescription)")
            } else if let token = token, let userID = FirebaseServiceImpl.shared.getCurrentUserUid() {
                let userRef =
                FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userID)
                    .child("fcm_token")
                
                userRef.setValue(token) { error, _ in
                    if let error = error {
                        print("Error al guardar el token de FCM: \(error.localizedDescription)")
                    } else {
                        print("Token de FCM actualizado correctamente")
                    }
                }
            }
        }
    }
}
