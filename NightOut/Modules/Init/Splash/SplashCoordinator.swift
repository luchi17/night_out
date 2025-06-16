import SwiftUI
import Combine

class SplashCoordinator: Hashable {

    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SplashCoordinator, rhs: SplashCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    let actions: SplashPresenterImpl.Actions
    
    
    init(actions: SplashPresenterImpl.Actions) {
        self.actions = actions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = SplashPresenterImpl(
            actions: self.actions,
            useCases: .init()
        )
        SplashView(presenter: presenter)
    }
}

