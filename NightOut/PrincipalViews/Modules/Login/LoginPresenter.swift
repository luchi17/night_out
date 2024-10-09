
import SwiftUI
import Combine
import FirebaseAuth

final class LoginViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var loading: Bool = false
    @Published var headerError: ErrorState?
    
    init() { }
    
}

protocol LoginPresenter {
    var viewModel: LoginViewModel { get }
    func transform(input: LoginPresenterImpl.ViewInputs)
}

final class LoginPresenterImpl: LoginPresenter {
    
    struct UseCases {
        let loginUseCase: LoginUseCase
        let signupUseCase: SignupUseCase
    }
    
    struct Actions {
        var goToTabView: VoidClosure
    }
    
    struct ViewInputs {
        let login: AnyPublisher<Void, Never>
        let signup: AnyPublisher<Void, Never>
        let signupWithGoogle: AnyPublisher<Void, Never>
        let signupWithApple: AnyPublisher<Void, Never>
    }
    
    var viewModel: LoginViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = LoginViewModel()
    }
    
    func transform(input: LoginPresenterImpl.ViewInputs) {
        loginListener(input: input)
        signupListener(input: input)
        loginGoogleListener(input: input)
        loginAppleListener(input: input)
    }
    
    func loginListener(input: LoginPresenterImpl.ViewInputs) {
        input
            .login
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.loginUseCase.execute(
                    email: self.viewModel.email,
                    password: self.viewModel.password
                )
                .mapError { error -> ErrorPresentationType in
                    return .makeCustom(title: "Error", description: error.localizedDescription)
                }
                .eraseToAnyPublisher()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error == nil {
                    self.viewModel.headerError = nil
                } else {
                    guard self.viewModel.loading else { return }
                    self.viewModel.headerError = ErrorState(errorOptional: error)
                }
            })
            .sink(receiveValue: { [weak self] _ in
                self?.actions.goToTabView()
            })
            .store(in: &cancellables)
    }
    
    #warning("Move to view with user data")
    func signupListener(input: LoginPresenterImpl.ViewInputs) {
        input
            .signup
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.signupUseCase.execute(
                    email: self.viewModel.email,
                    password: self.viewModel.password
                )
                .mapError { error -> ErrorPresentationType in
                    return .makeCustom(title: "Unable to register", description: error.localizedDescription)
                }
                .eraseToAnyPublisher()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error == nil {
                    self.viewModel.headerError = nil
                } else {
                    guard self.viewModel.loading else { return }
                    self.viewModel.headerError = ErrorState(errorOptional: error)
                }
            })
            .sink(receiveValue: { [weak self] _ in
                self?.actions.goToTabView()
            })
            .store(in: &cancellables)
    }
    
    func loginGoogleListener(input: LoginPresenterImpl.ViewInputs) {
        input
            .signupWithGoogle
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.loginUseCase.executeGoogle()
                    .mapError { error -> ErrorPresentationType in
                        return .makeCustom(title: "Unable to login with Google", description: error.localizedDescription)
                    }
                    .eraseToAnyPublisher()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error == nil {
                    self.viewModel.headerError = nil
                } else {
                    guard self.viewModel.loading else { return }
                    self.viewModel.headerError = ErrorState(errorOptional: error)
                }
            })
            .sink(receiveValue: { [weak self] _ in
                self?.actions.goToTabView()
            })
            .store(in: &cancellables)
        
    }
    
    func loginAppleListener(input: LoginPresenterImpl.ViewInputs) {
//        input
//            .signupWithApple
//            .withUnretained(self)
        
    }
}

#warning("donde compruebo si user is loggedin")
//self.isAuthenticated = Auth.auth().currentUser != nil
