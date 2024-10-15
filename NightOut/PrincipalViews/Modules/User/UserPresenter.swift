import Combine
import SwiftUI

class UserViewModel: ObservableObject {

    @Published var loading: Bool
    
    init(
        loading: Bool
    ) {
        self.loading = loading
    }
}

protocol UserPresenter {
    var viewModel: UserViewModel { get }
    func transform(input: UserPresenterImpl.Input)
}

final class UserPresenterImpl: UserPresenter {
    var viewModel: UserViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
        let logout: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
        let signOutUseCase: SignOutUseCase
    }
    
    struct Actions {
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases) {
        self.viewModel = UserViewModel(
            loading: false
        )
        self.actions = actions
        self.useCases = useCases
    }
    
    func transform(input: Input) {
        input
            .viewIsLoaded
            .withUnretained(self)
            .sink { presenter, _ in
                FirebaseServiceImpl.shared.appState.loadLoginState()
            }
            .store(in: &cancellables)
        
        input
            .logout
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.signOutUseCase.execute()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { error in
                print("Error")
            })
            .sink(receiveValue: { _ in
                FirebaseServiceImpl.shared.appState.isLoggedIn = false
            })
            .store(in: &cancellables)
            
    }
}
