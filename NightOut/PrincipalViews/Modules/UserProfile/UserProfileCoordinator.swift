
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
    
    init(
        actions: UserProfilePresenterImpl.Actions
    ) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = UserProfilePresenterImpl(
            useCases: .init(
                followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared),
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: actions
        )
        UserProfileView(presenter: presenter)
    }
}

