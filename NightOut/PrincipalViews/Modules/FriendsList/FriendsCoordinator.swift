
import SwiftUI
import Combine

class FriendsCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FriendsCoordinator, rhs: FriendsCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: FriendsPresenterImpl.Actions
    private let followerIds: [String]
    
    init(actions: FriendsPresenterImpl.Actions, followerIds: [String]) {
        self.actions = actions
        self.followerIds = followerIds
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = FriendsPresenterImpl(
            useCases: .init(
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared),
                companyDataUseCase: CompanyDataUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: actions
        )
        FriendsView(presenter: presenter, followerIds: followerIds)
    }
}

