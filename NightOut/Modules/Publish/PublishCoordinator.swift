import SwiftUI
import Combine

class PublishCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PublishCoordinator, rhs: PublishCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: PublishPresenterImpl.Actions
    
    init(actions: PublishPresenterImpl.Actions) {
        self.actions = actions
    }

    
    @ViewBuilder
    func build() -> some View {
        let presenter = PublishPresenterImpl(
            useCases: .init(),
            actions: actions
        )
        AddPostView(presenter: presenter)
    }

}


