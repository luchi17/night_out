
import SwiftUI
import Combine

class CommentsCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CommentsCoordinator, rhs: CommentsCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: CommentsPresenterImpl.Actions
    private let info: PostCommentsInfo
    
    init(
        actions: CommentsPresenterImpl.Actions,
        info: PostCommentsInfo
    ) {
        self.actions = actions
        self.info = info
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = CommentsPresenterImpl(
            useCases: .init(
                postsUseCase: PostsUseCaseImpl(repository: PostsRepositoryImpl.shared),
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared),
                companyDataUseCase: CompanyDataUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: actions,
            info: info
        )
        CommentsView(presenter: presenter)
    }
}

