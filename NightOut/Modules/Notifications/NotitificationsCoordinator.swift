
import SwiftUI
import Combine

class NotificationsCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NotificationsCoordinator, rhs: NotificationsCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: NotificationsPresenterImpl.Actions
    
    init(
        actions: NotificationsPresenterImpl.Actions
    ) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = NotificationsPresenterImpl(
            useCases: .init(
                notificationsUseCase: NotificationsUseCaseImpl(repository: NotificationsRepositoryImpl.shared),
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared),
                followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared),
                postsUseCase: PostsUseCaseImpl(repository: PostsRepositoryImpl.shared)
            ),
            actions: actions
        )
        NotificationsView(presenter: presenter)
    }
}

