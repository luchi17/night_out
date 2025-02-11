import SwiftUI
import Combine

class ForgotPasswordCoordinator: Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ForgotPasswordCoordinator, rhs: ForgotPasswordCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    init() {
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = ForgotPasswordPresenterImpl()
        ForgotPasswordView(presenter: presenter)
    }
    
}

