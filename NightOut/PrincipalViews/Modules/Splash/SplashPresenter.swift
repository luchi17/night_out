
import Combine
import UIKit

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
//        let viewIsLoaded: AnyPublisher<Void, Never>
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
    
    var timer: DispatchSourceTimer?
    
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
        input
            .login
            .withUnretained(self)
            .sink { _ in
            self.actions.onLogin()
        }
        .store(in: &cancellables)
        
        input
            .tabview
            .withUnretained(self)
            .sink { _ in
                self.actions.onMainFlow()
            }
            .store(in: &cancellables)
    }
    
    
}
