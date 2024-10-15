import Combine
import SwiftUI

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
//        let updateApplication: AnyPublisher<Void, Never>
//        let reload: AnyPublisher<Void, Never>
        let login: AnyPublisher<Void, Never>
        let tabview: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
    }
    
    struct Actions {
        let onMainFlow: VoidClosure
//        let onOnboardingFlow: VoidClosure
        let onLogin: VoidClosure
        //       , let onUpdateApplication: VoidClosure
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
        let timerPublisher =
        Timer.publish(every: 2.0, on: .main, in: .default)
            .autoconnect()
            .withUnretained(self)
            .map { _ in }
            .eraseToAnyPublisher()
        
        input
            .viewIsLoaded
            .withUnretained(self)
            .sink { presenter, _ in
                FirebaseServiceImpl.shared.appState.loadLoginState()
            }
            .store(in: &cancellables)
        
        input
            .viewIsLoaded
            .map { _ in }
            .merge(with: timerPublisher)
            .withUnretained(self)
            .sink { presenter, _ in
                print("Evento recibido (vista cargada o timer cumplido)")
                FirebaseServiceImpl.shared.appState.checkUserStatus() // Verificar con Firebase si está autenticado
                
                if FirebaseServiceImpl.shared.appState.isLoggedIn {
                    presenter.actions.onLogin()
                } else {
                    presenter.actions.onMainFlow()
                }
            }
            .store(in: &cancellables)
        
//        input
//            .login
//            .withUnretained(self)
//            .sink { _ in
//            self.actions.onLogin()
//        }
//        .store(in: &cancellables)
//        
//        input
//            .tabview
//            .withUnretained(self)
//            .sink { _ in
//                self.actions.onMainFlow()
//            }
//            .store(in: &cancellables)
    }
    
    
}

