import SwiftUI
import Combine

class SignUpCompanyCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SignUpCompanyCoordinator, rhs: SignUpCompanyCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: SignupCompanyPresenterImpl.Actions
    
    init(actions: SignupCompanyPresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        SignupCompanyView(presenter: SignupCompanyPresenterImpl(
            useCases: .init(
                signupUseCase: SignupUseCaseImpl(repository: AccountRepositoryImpl.shared),
                saveCompanyUseCase: SaveCompanyUseCaseImpl(repository: AccountRepositoryImpl.shared)),
            actions: actions
        ))
    }
    
}

