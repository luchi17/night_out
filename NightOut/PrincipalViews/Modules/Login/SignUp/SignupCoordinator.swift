import SwiftUI
import Combine

class SignupCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SignupCoordinator, rhs: SignupCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: SignupPresenterImpl.Actions
    
    init(actions: SignupPresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        SignupView(presenter: SignupPresenterImpl(
            useCases: .init(signupUseCase: SignupUseCaseImpl(repository: AccountRepositoryImpl.shared)),
            actions: actions
        ))
    }
    
}

