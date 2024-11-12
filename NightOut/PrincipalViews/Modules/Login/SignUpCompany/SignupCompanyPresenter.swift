import SwiftUI
import Combine
import FirebaseAuth

enum SelectedTag {
    case sportCasual
    case informal
    case semiInformal
    case none
    
    var title: String {
        switch self {
        case .sportCasual:
            return "Sport-Casual"
        case .informal:
            return "Informal"
        case .semiInformal:
            return "Semi-informal"
        case .none:
            return "SELECT TAG"
        }
    }
}

final class SignupCompanyViewModel: ObservableObject {
    
    @Published var userName: String = ""
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var endTime: String = ""
    @Published var startTime: String = ""
    @Published var selectedTag: SelectedTag = .none
    @Published var imageData: Data? = nil
    @Published var location: String = ""
    @Published var loading: Bool = false
    @Published var headerError: ErrorState?
    
    var imageUrl: String?
    
    init() {
        self.startTime = timeString(from: Date())
        self.endTime = timeString(from: Date())
    }
    
    // Formatear la fecha en una cadena de hora:minuto
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
}

protocol SignupCompanyPresenter {
    var viewModel: SignupCompanyViewModel { get }
    func transform(input: SignupCompanyPresenterImpl.ViewInputs)
}

final class SignupCompanyPresenterImpl: SignupCompanyPresenter {
    
    struct UseCases {
        let signupUseCase: SignupUseCase
        let saveCompanyUseCase: SaveCompanyUseCase
    }
    
    struct Actions {
        var goToTabView: VoidClosure
        var backToLogin: VoidClosure
    }
    
    struct ViewInputs {
        let signupCompany: AnyPublisher<Void, Never>
        let login: AnyPublisher<Void, Never>
    }
    
    var viewModel: SignupCompanyViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = SignupCompanyViewModel()
    }
    
    func transform(input: SignupCompanyPresenterImpl.ViewInputs) {
        
        input
            .login
            .withUnretained(self)
            .sink { presenter, _ in
                self.actions.backToLogin()
            }
            .store(in: &cancellables)
        
        signupListener(input: input)
    }
    
    func signupListener(input: SignupCompanyPresenterImpl.ViewInputs) {
        let signuppublisher =
        input
            .signupCompany
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                return presenter.useCases.signupUseCase.executeCompany(
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
           
        let saveImagePublisher = signuppublisher
            .withUnretained(self)
            .performRequest(request: { presenter, _ -> AnyPublisher<String?, Never> in
                guard let imageData = presenter.viewModel.imageData else {
                    return Just(nil)
                        .eraseToAnyPublisher()
                }
                return presenter.useCases.saveCompanyUseCase.executeGetImageUrl(imageData: imageData)
                    .eraseToAnyPublisher()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { _ in  })
            .handleEvents(receiveOutput: { [weak self] imageUrl in
                if let imageUrl = imageUrl {
                    self?.viewModel.imageUrl = imageUrl
                } else {
                    print("Image url no se ha podido obtener")
                }
            })
            .eraseToAnyPublisher()
        
        saveImagePublisher
            .withUnretained(self)
            .performRequest(request: { presenter, imageUrl in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(false)
                        .eraseToAnyPublisher()
                }
       
                let model = CompanyModel(
                    email: self.viewModel.email,
                    endTime: self.viewModel.endTime,
                    selectedTag: self.viewModel.selectedTag == .none ? "Etiqueta" : self.viewModel.selectedTag.title,
                    fullname: self.viewModel.fullName,
                    username: self.viewModel.userName,
                    imageUrl: self.viewModel.imageUrl,
                    location: self.viewModel.location,
                    startTime: self.viewModel.startTime,
                    uid: uid
                )
                return presenter.useCases.saveCompanyUseCase.execute(model: model)
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
                    self.viewModel.headerError = ErrorState(error: .makeCustom(title: "Error", description: "Could not save company"))
                }
            })
            .sink(receiveValue: { [weak self] saved in
                if saved {
                    self?.viewModel.headerError = nil
                    self?.actions.goToTabView()
                } else {
                    self?.viewModel.headerError = ErrorState(error: .makeCustom(title: "Error", description: "Could not save user"))
                }
               
            })
            .store(in: &cancellables)
    }
}
