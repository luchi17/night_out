import SwiftUI
import Combine
import FirebaseAuth

enum SelectedTag {
    case sportCasual
    case informal
    case semiInformal
    case label
    
    var title: String {
        switch self {
        case .sportCasual:
            return "Sport-Casual"
        case .informal:
            return "Informal"
        case .semiInformal:
            return "Semi-informal"
        case .label:
            return "Etiqueta"
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
    @Published var selectedTag: SelectedTag = .label
    @Published var image: String = ""
    @Published var location: String = ""
    @Published var loading: Bool = false
    @Published var headerError: ErrorState?
    
    init() { }
    
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
            .performRequest(request: { presenter, _ in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(false)
                        .eraseToAnyPublisher()
                }
       
                let model = CompanyModel(
                    email: self.viewModel.email,
                    endTime: self.viewModel.endTime,
                    selectedTag: self.viewModel.selectedTag.title,
                    fullname: self.viewModel.fullName,
                    username: self.viewModel.userName,
                    image: self.viewModel.image,
                    location: self.viewModel.location,
                    startTime: self.viewModel.startTime,
                    uid: uid
                )
                return presenter.useCases.saveCompanyUseCase.execute(model: model)
                    .eraseToAnyPublisher()
            })
            .sink(receiveValue: { [weak self] saved in
                if saved {
                    self?.actions.goToTabView()
                } else {
                    self?.viewModel.headerError = ErrorState(error: .makeCustom(title: "Error", description: "User ID not found"))
                }
               
            })
            .store(in: &cancellables)
    }
}
