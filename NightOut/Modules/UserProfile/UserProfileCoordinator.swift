
import SwiftUI
import Combine

class UserProfileCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UserProfileCoordinator, rhs: UserProfileCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: UserProfilePresenterImpl.Actions
    private let model: ProfileModel
    
    init(
        actions: UserProfilePresenterImpl.Actions,
        model: ProfileModel
    ) {
        self.actions = actions
        self.model = model
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = UserProfilePresenterImpl(
            useCases: .init(
                followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared),
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared),
                clubUseCase: ClubUseCaseImpl(repository: ClubRepositoryImpl.shared),
                noficationsUsecase: NotificationsUseCaseImpl(repository: NotificationsRepositoryImpl.shared),
                companyDataUseCase: CompanyDataUseCaseImpl(repository: AccountRepositoryImpl.shared), postsUseCase: PostsUseCaseImpl(repository: PostsRepositoryImpl.shared)
            ),
            actions: actions,
            model: model
        )
        
        UserProfileView(presenter: presenter)
    }
}

