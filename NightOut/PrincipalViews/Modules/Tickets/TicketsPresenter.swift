import Combine
import SwiftUI

class TicketsViewModel: ObservableObject {

    @Published var loading: Bool
    
    init(
        loading: Bool
    ) {
        self.loading = loading
    }
}

protocol TicketsPresenter {
    var viewModel: TicketsViewModel { get }
    func transform(input: TicketsPresenterImpl.Input)
}

final class TicketsPresenterImpl: TicketsPresenter {
    var viewModel: TicketsViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
        let logout: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
        let signOutUseCase: SignOutUseCase
    }
    
    struct Actions {
        let backToLogin: VoidClosure
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases) {
        self.viewModel = TicketsViewModel(
            loading: false
        )
        self.actions = actions
        self.useCases = useCases
    }
    
    func transform(input: Input) {
        input
            .logout
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.signOutUseCase.execute()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { error in
                if let error = error {
                    print("Error: " + error.localizedDescription)
                }
            })
            .sink(receiveValue: { [weak self] _ in
                AppState.shared.shouldShowSplashVideo = false
                UserDefaults.clearAll()
                self?.actions.backToLogin()
            })
            .store(in: &cancellables)
            
    }
}
