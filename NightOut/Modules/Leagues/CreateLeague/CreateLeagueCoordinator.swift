
import SwiftUI
import Combine

class CreateLeagueCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CreateLeagueCoordinator, rhs: CreateLeagueCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: CreateLeaguePresenterImpl.Actions
    
    init(actions: CreateLeaguePresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = CreateLeaguePresenterImpl(
            useCases: .init(),
            actions: actions
        )
        CreateLeagueView(presenter: presenter)
    }
}

