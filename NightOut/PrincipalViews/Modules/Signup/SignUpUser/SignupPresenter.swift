import SwiftUI
import Combine
import FirebaseAuth

final class SignupViewModel: ObservableObject {
    
    @Published var userName: String = ""
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var loading: Bool = false
    @Published var headerError: ErrorState?
    
    init() { }
    
}

protocol SignupPresenter {
    var viewModel: SignupViewModel { get }
    func transform(input: SignupPresenterImpl.ViewInputs)
}

final class SignupPresenterImpl: SignupPresenter {
    
    struct UseCases {
        let signupUseCase: SignupUseCase
        let saveUserUseCase: SaveUserUseCase
    }
    
    struct Actions {
        var goToTabView: VoidClosure
        var backToLogin: VoidClosure
    }
    
    struct ViewInputs {
        let signup: AnyPublisher<Void, Never>
        let login: AnyPublisher<Void, Never>
    }
    
    var viewModel: SignupViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = SignupViewModel()
    }
    
    func transform(input: SignupPresenterImpl.ViewInputs) {
        
        input
            .login
            .withUnretained(self)
            .sink { presenter, _ in
                self.actions.backToLogin()
            }
            .store(in: &cancellables)
        
        signupListener(input: input)
    }
    
    func signupListener(input: SignupPresenterImpl.ViewInputs) {
        let signuppublisher =
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
           
        signuppublisher
            .withUnretained(self)
            .performRequest(request: { presenter, _ -> AnyPublisher<(Bool, UserModel?), Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just((false, nil))
                        .eraseToAnyPublisher()
                }
                let model = UserModel(
                    uid: uid,
                    fullname: self.viewModel.fullName,
                    username: self.viewModel.userName,
                    email: self.viewModel.email
                )
                return presenter.useCases.saveUserUseCase.execute(model: model)
                    .map({ ($0, model)})
                    .eraseToAnyPublisher()
            })
            .sink(receiveValue: { [weak self] data in
                if data.0, let _ = data.1 {
                    self?.viewModel.headerError = nil
                    UserDefaults.setImUser(true)
                    self?.actions.goToTabView()
                } else {
                    self?.viewModel.headerError = ErrorState(error: .makeCustom(title: "Error", description: "User ID not found"))
                }
               
            })
            .store(in: &cancellables)
    }
}

