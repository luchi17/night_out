import SwiftUI
import Combine
import FirebaseAuth

final class SignupViewModel: ObservableObject {
    
    @Published var userName: String = ""
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var gender: Gender?
    @Published var password: String = ""
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    @Published var selectedImage: UIImage?
    @Published var imageData: Data? = nil
    @Published var fcmToken: String = ""
    
    var imageUrl: String?
    
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
        let saveCompanyUseCase: SaveCompanyUseCase
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
           
        let saveImagePublisher = signuppublisher
            .withUnretained(self)
            .flatMapLatest({ presenter, fcmToken -> AnyPublisher<(String?, String), Never> in
                guard let imageData = presenter.viewModel.imageData else {
                    return Just((nil, fcmToken))
                        .eraseToAnyPublisher()
                }
                return presenter.useCases.saveCompanyUseCase.executeGetImageUrl(imageData: imageData)
                    .map({ ($0, fcmToken)})
                    .handleEvents(receiveOutput: { [weak self] data in
                        if let imageUrl = data.0 {
                            self?.viewModel.imageUrl = imageUrl
                        } else {
                            print("Image url no se ha podido obtener")
                        }
                        self?.viewModel.fcmToken = data.1
                        
                    }, receiveRequest: { [weak self] _ in
                        self?.viewModel.loading = true
                    })
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
        
        saveImagePublisher
            .withUnretained(self)
            .performRequest(request: { presenter, imageUrl -> AnyPublisher<(Bool, UserModel?), Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just((false, nil))
                        .eraseToAnyPublisher()
                }
                let model = UserModel(
                    uid: uid,
                    fullname: presenter.viewModel.fullName,
                    username: presenter.viewModel.userName.lowercased(),
                    email: presenter.viewModel.email.lowercased(),
                    gender: presenter.viewModel.gender?.firebaseTitle,
                    image: presenter.viewModel.imageUrl,
                    fcm_token: presenter.viewModel.fcmToken
                )
                return presenter.useCases.saveUserUseCase.execute(model: model)
                    .map({ ($0, model)})
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .flatMap({ presenter, data in
                presenter.useCases.saveUserUseCase.executeTerms()
                    .map({ _ in data })
                    .eraseToAnyPublisher()
            })
            .sink(receiveValue: { [weak self] data in
                self?.viewModel.loading = false
                if data.0, let model = data.1 {
                    UserDefaults.setIsFirstLoggedIn(true)
                    UserDefaults.setUserModel(model)
                    self?.actions.goToTabView()
                } else {
                    self?.viewModel.toast = .custom(.init(title: "Error", description: "User ID not found", image: nil))
                }
               
            })
            .store(in: &cancellables)
    }
}

