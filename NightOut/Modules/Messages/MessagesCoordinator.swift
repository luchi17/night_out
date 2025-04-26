
import SwiftUI
import Combine

class MessagesCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MessagesCoordinator, rhs: MessagesCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: MessagesPresenterImpl.Actions
    
    init(
        actions: MessagesPresenterImpl.Actions
    ) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = MessagesPresenterImpl(
            useCases: .init(),
            actions: actions
        )
        MessagesView(presenter: presenter)
    }
}

