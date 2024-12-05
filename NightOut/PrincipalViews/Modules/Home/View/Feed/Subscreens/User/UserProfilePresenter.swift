import SwiftUI
import Combine

struct UserProfileInfo {
    var profileId: String
    var profileImageUrl: String?
    var username: String
    var fullName: String
}

final class UserProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = "Nombre no disponible"
    @Published var fullname: String = "Username no disponible"
    @Published var followersCount: String = "0"
    @Published var discosCount: String = "0"
    @Published var copasCount: String = "0"
    
    init(profileImageUrl: String? = nil, username: String, fullname: String, discosCount: String, copasCount: String) {
        self.profileImageUrl = profileImageUrl
        self.username = username
        self.fullname = fullname
        self.discosCount = discosCount
        self.copasCount = copasCount
    }
}

protocol UserProfilePresenter {
    var viewModel: UserProfileViewModel { get }
    func transform(input: UserProfilePresenterImpl.ViewInputs)
}

final class UserProfilePresenterImpl: UserProfilePresenter {
    
    struct UseCases {
        let followUseCase: FollowUseCase
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
    }
    
    var viewModel: UserProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private let info: UserProfileInfo
    
    init(
        useCases: UseCases,
        actions: Actions,
        info: UserProfileInfo
    ) {
        self.actions = actions
        self.useCases = useCases
        self.info = info

        viewModel = UserProfileViewModel(
            profileImageUrl: info.profileImageUrl,
            username: info.username,
            fullname: info.fullName,
            discosCount: "0",
            copasCount: "0"
            
        )
    }
    
    func transform(input: UserProfilePresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.followUseCase.fetchFollow(id: presenter.info.profileId)
            })
            .withUnretained(self)
            .sink { presenter, followModel in
                presenter.viewModel.followersCount = String(followModel?.followers?.count ?? 0)
            }
            .store(in: &cancellables)
    }
}

private extension UserProfilePresenterImpl {
    
    
}
