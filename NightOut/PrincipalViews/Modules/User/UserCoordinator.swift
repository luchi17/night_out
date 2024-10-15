import SwiftUI
import Combine

struct UserCoordinator {
    
    private let actions: UserPresenterImpl.Actions
    
    init(actions: UserPresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        UserProfileView(presenter: UserPresenterImpl(
            actions: actions,
            useCases: .init(signOutUseCase: SignOutUseCaseImpl(repository: AccountRepositoryImpl.shared))
        ))
    }
}


