
import SwiftUI
import Combine
import FirebaseAuth

final class LoginViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    init() { }
    
}

protocol LoginPresenter {
    var viewModel: LoginViewModel { get }
    func transform(input: LoginPresenterImpl.ViewInputs)
}

final class LoginPresenterImpl: LoginPresenter {
    
    struct UseCases {
        let loginUseCase: LoginUseCase
        let companyLocationsUseCase: CompanyLocationsUseCase
        let userDataUseCase: UserDataUseCase
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
            .filter({ [weak self] _ in
                if (self?.viewModel.password.isEmpty ?? true) || (self?.viewModel.email.isEmpty ?? true) {
                    self?.viewModel.toast = .custom(.init(title: "Error", description: "Por favor, ingresa tu email y contraseña.", image: nil))
                    return false
                }
                
                return true
            })
            .filter({ [weak self] _ in
                if !FirebaseServiceImpl.shared.getIsLoggedin() {
                    self?.viewModel.toast = .custom(.init(title: "Error", description: "Usuario no válido.", image: nil))
                    return false
                }
                return true
            })
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.loginUseCase.execute(
                    email: presenter.viewModel.email,
                    password: presenter.viewModel.password
                )
                .eraseToAnyPublisher()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error != nil {
                    self.viewModel.toast = .custom(.init(title: "Error", description: error?.localizedDescription, image: nil))
                }
                
            })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.companyLocationsUseCase.fetchCompanyLocations()
            })
            .withUnretained(self)
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
            }, loadingClosure: { _ in
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error != nil {
                    self.viewModel.toast = .custom(.init(title: "Error", description: error?.localizedDescription, image: nil))
                }
            })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.companyLocationsUseCase.fetchCompanyLocations()
            })
            .withUnretained(self)
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
