import SwiftUI
import Combine

class SplashCoordinator {

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

