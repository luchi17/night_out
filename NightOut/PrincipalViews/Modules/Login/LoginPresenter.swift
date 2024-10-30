
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
    }
    
    struct Actions {
        var goToTabView: VoidClosure
        var goToRegisterUser: VoidClosure
        var goToRegisterCompany: VoidClosure
    }
    
    struct ViewInputs {
        let login: AnyPublisher<Void, Never>
        let signupUser: AnyPublisher<Void, Never>
        let signupCompany: AnyPublisher<Void, Never>
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
        signupCompanyListener(input: input)
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
    
    func signupListener(input: LoginPresenterImpl.ViewInputs) {
        input
            .signupUser
            .withUnretained(self)
            .sink(receiveValue: { presenter, _ in
                self.actions.goToRegisterUser()
            })
            .store(in: &cancellables)
    }
    
    func signupCompanyListener(input: LoginPresenterImpl.ViewInputs) {
        input
            .signupCompany
            .withUnretained(self)
            .sink(receiveValue: { presenter, _ in
                self.actions.goToRegisterCompany()
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
