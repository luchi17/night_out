import SwiftUI
import Combine

class LoginCoordinator: Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LoginCoordinator, rhs: LoginCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: LoginPresenterImpl.Actions
    
    init(actions: LoginPresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        LoginView(presenter: LoginPresenterImpl(
            useCases: .init(
                loginUseCase: LoginUseCaseImpl(repository: AccountRepositoryImpl.shared),
                companyLocationsUseCase: CompanyLocationsUseCaseImpl(repository: LocationRepositoryImpl.shared)),
            actions: actions
        ))
    }
    
}

