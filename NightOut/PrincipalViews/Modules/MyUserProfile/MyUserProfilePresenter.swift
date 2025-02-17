import SwiftUI
import Combine

final class MyUserProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = ""
    @Published var fullname: String = ""
    @Published var woman: Bool = false
    @Published var followersCount: String = "0"
    @Published var copasCount: String = "0"
    @Published var discosCount: String = "0"
    
    @Published var companyMenuSelection: CompanyMenuSelection?
}

protocol MyUserProfilePresenter {
    var viewModel: MyUserProfileViewModel { get }
    func transform(input: MyUserProfilePresenterImpl.ViewInputs)
}

final class MyUserProfilePresenterImpl: MyUserProfilePresenter {
    
    struct UseCases {
        let followUseCase: FollowUseCase
        let userDataUseCase: UserDataUseCase
    }
    
    struct Actions {
        let backToLogin: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let goToLogin: AnyPublisher<Void, Never>
    }
    
    var viewModel: MyUserProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases

        viewModel = MyUserProfileViewModel()
    }
    
    func transform(input: MyUserProfilePresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .filter { presenter, _ in
                return FirebaseServiceImpl.shared.getImUser()
            }
            .flatMap({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: uid)
            })
            .withUnretained(self)
            .flatMap({ presenter, followModel -> AnyPublisher<(FollowModel?, UserModel?), Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just((nil, nil)).eraseToAnyPublisher()
                }
                return presenter.useCases.userDataUseCase.getUserInfo(uid: uid)
                    .map({ (followModel, $0 )})
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .sink { presenter, data in
                let userModel = UserDefaults.getUserModel()
                let profileImage = userModel?.image
                let username = userModel?.username
                let fullname = userModel?.fullname
                
                presenter.viewModel.profileImageUrl = profileImage
                presenter.viewModel.username = username ?? "Username no disponible"
                presenter.viewModel.fullname = fullname ?? "Fullname no disponible"
                presenter.viewModel.followersCount = String(data.0?.followers?.count ?? 0)
                presenter.viewModel.copasCount = String(data.1?.MisCopas ?? 0)
                
                let uniqueDiscotecasCount = Set(data.1?.MisEntradas?.values.map { $0.discoteca } ?? []).count

                presenter.viewModel.discosCount = String(uniqueDiscotecasCount)
            }
            .store(in: &cancellables)
        
        input
            .viewDidLoad
            .withUnretained(self)
            .filter { presenter, _ in
                return !FirebaseServiceImpl.shared.getImUser()
            }
            .flatMap({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: uid)
            })
            .withUnretained(self)
            .sink { presenter, followModel in
                let model = UserDefaults.getCompanyUserModel()
                let profileImage = model?.imageUrl
                let username = model?.username
                let fullname = model?.fullname
                
                presenter.viewModel.profileImageUrl = profileImage
                presenter.viewModel.username = username ?? "Username no disponible"
                presenter.viewModel.fullname = fullname ?? "Fullname no disponible"
                presenter.viewModel.followersCount = String(followModel?.followers?.count ?? 0)
            }
            .store(in: &cancellables)
        
        input
            .goToLogin
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.backToLogin()
            }
            .store(in: &cancellables)
        
        viewModel
            .$companyMenuSelection
            .removeDuplicates()
            .withUnretained(self)
            .sink { presenter, value in
                #warning("TODO: actions")
                switch value {
                case .lectorEntradas:
                    print("lectorEntradas")
                case .gestorEventos:
                    print("gestorEventos")
                case .publicidad:
                    print("publicidad")
                case .metodosDePago:
                    print("metodosDePago")
                case .ventas:
                    print("ventas")
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}


