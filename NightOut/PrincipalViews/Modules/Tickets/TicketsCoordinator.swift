
import SwiftUI
import Combine

struct TicketsCoordinator {
    
    private let actions: TicketsPresenterImpl.Actions
    
    init(actions: TicketsPresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        TicketsView(presenter: TicketsPresenterImpl(
            actions: actions,
            useCases: .init(signOutUseCase: SignOutUseCaseImpl(repository: AccountRepositoryImpl.shared))
        ))
    }
}
