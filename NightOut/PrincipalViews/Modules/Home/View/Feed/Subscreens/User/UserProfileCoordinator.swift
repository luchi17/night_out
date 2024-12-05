
import SwiftUI
import Combine

class UserProfileCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UserProfileCoordinator, rhs: UserProfileCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: UserProfilePresenterImpl.Actions
    private let info: UserProfileInfo
    
    init(
        actions: UserProfilePresenterImpl.Actions,
        info: UserProfileInfo
    ) {
        self.actions = actions
        self.info = info
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = UserProfilePresenterImpl(
            useCases: .init(),
            actions: actions,
            info: info
        )
        UserProfileView(presenter: presenter)
    }
}

