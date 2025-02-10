
import SwiftUI
import Combine

class SearchCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchCoordinator, rhs: SearchCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: SearchPresenterImpl.Actions
    
    init(actions: SearchPresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = SearchPresenterImpl(
            useCases: .init(followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared)),
            actions: actions
        )
        SearchView(presenter: presenter)
    }
}

