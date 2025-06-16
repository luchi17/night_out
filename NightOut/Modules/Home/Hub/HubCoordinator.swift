import SwiftUI
import Combine

class HubCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HubCoordinator, rhs: HubCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: HubPresenterImpl.Actions
    
    init(actions: HubPresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = HubPresenterImpl(
            useCases: .init(),
            actions: actions
        )
        HubView(presenter: presenter)
    }
}


