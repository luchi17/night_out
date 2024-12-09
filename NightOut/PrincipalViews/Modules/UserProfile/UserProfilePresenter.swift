import SwiftUI
import Combine


final class UserProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = ""
    @Published var fullname: String = ""
    @Published var followersCount: String = "0"
    @Published var copasCount: String = "0"
    @Published var discosCount: String = "0"
    
    @Published var loading: Bool = false
    
    init(profileImageUrl: String?, username: String?, fullname: String?) {
        self.profileImageUrl = profileImageUrl
        self.username = username ?? "Nombre no disponible"
        self.fullname = fullname ?? "Username no disponible"
    }
    
}

protocol UserProfilePresenter {
    var viewModel: UserProfileViewModel { get }
    func transform(input: UserProfilePresenterImpl.ViewInputs)
}

final class UserProfilePresenterImpl: UserProfilePresenter {
    
    struct UseCases {
        let followUseCase: FollowUseCase
        let userDataUseCase: UserDataUseCase
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let editProfile: AnyPublisher<Void, Never>
    }
    
    var viewModel: UserProfileViewModel
    
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
        
        viewModel = UserProfileViewModel(
            profileImageUrl: profileImage,
            username: username,
            fullname: fullname
        )
    }
    
    func transform(input: UserProfilePresenterImpl.ViewInputs) {
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
            .editProfile
            .withUnretained(self)
            .sink { presenter, _ in
                #warning("TODO: Open app settings")
            }
            .store(in: &cancellables)
    }
}


