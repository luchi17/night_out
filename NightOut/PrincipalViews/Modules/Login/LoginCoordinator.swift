import SwiftUI
import Combine

class LoginCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: LoginCoordinator, rhs: LoginCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    @ViewBuilder
    func build() -> some View {
        LoginView()
    }
    
}

