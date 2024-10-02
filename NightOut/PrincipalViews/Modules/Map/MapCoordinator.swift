
import SwiftUI
import Combine

public struct MapCoordinator: CoordinatorType {
    private let router: RouterType
    private let openMaps: (Double, Double) -> Void
    
    public init(router: RouterType,
                openMaps: @escaping (Double, Double) -> Void) {
        self.router = router
        self.openMaps = openMaps
    }
    
    public func start() {
        let presenter = LocationsMapPresenterImpl(
            useCases: .init(),
            actions: .init(onOpenMaps: openMaps)
        )
        let view = LocationsMapView(presenter: presenter)
        let vc = HostingController(rootView: view)
        router.pushViewController(vc, animated: true)
    }
    
    public func close(_ completion: VoidClosure?) {
        router.close(completion)
    }
}
