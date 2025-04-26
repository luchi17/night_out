
import SwiftUI
import Combine

class TinderCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TinderCoordinator, rhs: TinderCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: TinderPresenterImpl.Actions
    
    init(
        actions: TinderPresenterImpl.Actions
    ) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = TinderPresenterImpl(
            useCases: .init(
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared),
                clubUseCase: ClubUseCaseImpl(repository: ClubRepositoryImpl.shared)
            ),
            actions: actions
        )
        
        TinderView(presenter: presenter)
    }
}

