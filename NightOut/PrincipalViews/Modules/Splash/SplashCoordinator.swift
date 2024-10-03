import SwiftUI
import Combine

class SplashCoordinator {

    let actions: SplashPresenterImpl.Actions
    
    
    init(actions: SplashPresenterImpl.Actions) {
        self.actions = actions
    }
    
    func start() -> SplashView {
        let presenter = SplashPresenterImpl(
            actions: self.actions,
            useCases: .init()
        )
        return SplashView(presenter: presenter)
    }
}

