
import SwiftUI
import Combine

class LeagueDetailCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LeagueDetailCoordinator, rhs: LeagueDetailCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: LeagueDetailPresenterImpl.Actions
    private let league: League
    
    init(actions: LeagueDetailPresenterImpl.Actions, league: League) {
        self.actions = actions
        self.league = league
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = LeagueDetailPresenterImpl(
            useCases: .init(
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared),
                companyDataUseCase: CompanyDataUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: actions,
            league: league
        )
        LeagueDetailView(presenter: presenter)
    }
}

