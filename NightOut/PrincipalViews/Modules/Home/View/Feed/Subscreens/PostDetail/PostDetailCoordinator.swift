
import SwiftUI
import Combine

class PostDetailCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PostDetailCoordinator, rhs: PostDetailCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: PostDetailPresenterImpl.Actions
    private let post: NotificationModelForView
    
    init(
        actions: PostDetailPresenterImpl.Actions,
        post: NotificationModelForView
    ) {
        self.actions = actions
        self.post = post
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = PostDetailPresenterImpl(
            useCases: .init(),
            actions: actions,
            post: post
        )
        PostDetailView(presenter: presenter)
    }
}

