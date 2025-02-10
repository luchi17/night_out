
import SwiftUI
import Combine

class PrivateUserProfileCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PrivateUserProfileCoordinator, rhs: PrivateUserProfileCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: PrivateUserProfilePresenterImpl.Actions
    private let model: ProfileModel
    
    init(
        actions: PrivateUserProfilePresenterImpl.Actions,
        model: ProfileModel
    ) {
        self.actions = actions
        self.model = model
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = PrivateUserProfilePresenterImpl(
            useCases: .init(
                followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared),
                noficationsUsecase: NotificationsUseCaseImpl(repository: NotificationsRepositoryImpl.shared)
            ),
            actions: actions,
            model: model
        )
        
        PrivateUserProfileView(presenter: presenter)
    }
}

