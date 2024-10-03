
import SwiftUI
import Combine

class HomeCoordinator: ObservableObject {
    
    
    init() {
    }
    
    func start() -> HomeView {
        return HomeView()
    }
}

