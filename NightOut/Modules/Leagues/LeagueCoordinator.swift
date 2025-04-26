
import SwiftUI
import Combine

class LeagueCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LeagueCoordinator, rhs: LeagueCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: LeaguePresenterImpl.Actions
    
    init(actions: LeaguePresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = LeaguePresenterImpl(
            useCases: .init(
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared),
                companyDataUseCase: CompanyDataUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: actions
        )
        LeagueView(presenter: presenter)
    }
}

