
import SwiftUI
import Combine

class UserPostProfileCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UserPostProfileCoordinator, rhs: UserPostProfileCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: UserPostProfilePresenterImpl.Actions
    private let info: UserPostProfileInfo
    
    init(
        actions: UserPostProfilePresenterImpl.Actions,
        info: UserPostProfileInfo
    ) {
        self.actions = actions
        self.info = info
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = UserPostProfilePresenterImpl(
            useCases: .init(followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared),
                            postsUseCase: PostsUseCaseImpl(repository: PostsRepositoryImpl.shared)),
            actions: actions,
            info: info
        )
        UserPostProfileView(presenter: presenter)
    }
}

