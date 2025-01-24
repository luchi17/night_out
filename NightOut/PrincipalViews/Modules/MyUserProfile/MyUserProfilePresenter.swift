import SwiftUI
import Combine


final class MyUserProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = ""
    @Published var fullname: String = ""
    @Published var followersCount: String = "0"
    @Published var copasCount: String = "0"
    @Published var discosCount: String = "0"
    
    @Published var loading: Bool = false
    
    init(profileImageUrl: String?, username: String?, fullname: String?) {
        self.profileImageUrl = profileImageUrl
        self.username = username ?? "Username no disponible"
        self.fullname = fullname ?? "Fullname no disponible"
    }
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
        
        let userModel = UserDefaults.getUserModel()
        let profileImage = userModel?.image
        let username = userModel?.username
        let fullname = userModel?.fullname
        
        viewModel = MyUserProfileViewModel(
            profileImageUrl: profileImage,
            username: username,
            fullname: fullname
        )
    }
    
    func transform(input: MyUserProfilePresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .flatMap({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: uid)
            })
            .handleEvents(receiveRequest: { [weak self] _ in
                self?.viewModel.loading = true
            })
            .withUnretained(self)
            .sink { presenter, followModel in
                presenter.viewModel.loading = false
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
        
        
    }
}


