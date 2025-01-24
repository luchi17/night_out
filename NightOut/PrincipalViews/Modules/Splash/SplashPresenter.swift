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
        let timerPublisher =
        Timer.publish(every: 2.0, on: .main, in: .default)
            .autoconnect()
            .first()
            .map { _ in }
            .eraseToAnyPublisher()
        
        timerPublisher
            .map { _ in }
            .combineLatest(input.viewIsLoaded)
            .sink { [weak self] _ in
                if FirebaseServiceImpl.shared.getIsLoggedin() {
                    self?.actions.onMainFlow()
                } else {
                    self?.actions.onLogin()
                }
            }
            .store(in: &cancellables)
    }
}
