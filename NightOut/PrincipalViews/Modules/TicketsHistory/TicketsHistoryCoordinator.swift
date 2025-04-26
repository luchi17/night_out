import SwiftUI
import Combine

class TicketsHistoryCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TicketsHistoryCoordinator, rhs: TicketsHistoryCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: TicketsHistoryPresenterImpl.Actions
    
    init(actions: TicketsHistoryPresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        TicketsHistoryView(presenter: TicketsHistoryPresenterImpl(
            actions: actions,
            useCases: .init()
        ))
    }
}
