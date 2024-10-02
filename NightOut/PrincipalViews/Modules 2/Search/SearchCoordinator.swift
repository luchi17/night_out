
import SwiftUI
import Combine

public struct SearchCoordinator: CoordinatorType {
    private let router: RouterType
    
    public init(router: RouterType) {
        self.router = router
    }
    
    public func start() {
        let vc = HostingController(rootView: SearchView())
        router.pushViewController(vc, animated: true)
    }
    
    public func close(_ completion: VoidClosure?) {
        router.close(completion)
    }
}

