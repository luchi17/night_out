//
//  TabViewModel.swift
//  NightOut
//
//  Created by Apple on 29/9/24.
//

import SwiftUI
import Combine

enum TabType: Equatable {
    case home
    case search
    case publish
    case map
    case user
    
    public static func == (lhs: TabType, rhs: TabType) -> Bool {
        switch(lhs, rhs) {
        case (.home, .home), (.search, .search), (.publish, .publish), (.map, .map), (.user, .user):
            return true
        default:
            return false
        }
    }
}

class TabViewCoordinator: CoordinatorType {
    
    private let router: RouterType
    private let selectedTab: TabType?
    private let openMaps: (Double, Double) -> Void
    
    init(
        router: RouterType,
        selectedTab: TabType?,
        openMaps: @escaping (Double, Double) -> Void
    ) {
        self.router = router
        self.selectedTab = selectedTab
        self.openMaps = openMaps
    }
    
    func start() {
        navigateToTabBarView(selectedTab: selectedTab)
    }

    func close(_ completion: VoidClosure?) {
        router.close(completion)
    }
    
    public func makeTabBar(selectedTab: TabType?,
                           flowFactory: @escaping (TabType) -> UIViewController) -> UIViewController {
        let viewModel = TabViewModel(selectedTab: selectedTab)
//        return TabBarViewController(
//            tabFactory: TabBarFactory(
//                tabFlowFactory: flowFactory
//            ),
//            viewModel: viewModel
//        )
//        
        let view = TabViewScreen(viewModel: viewModel)
        
        return HostingController(rootView: view)
    }
    
    func navigateToTabBarView(selectedTab: TabType?) {
        let vc = makeTabBar(selectedTab: selectedTab, flowFactory: {
            switch $0 {
            case .home:
                return self.makeHomeFlow()
            case .search:
                return self.makeSearchFlow()
            case .publish:
                return self.makePublishFlow()
            case .map:
                return self.makeMapsFlow()
            case .user:
                return self.makeUserFlow()
            }
        })
        router.pushViewController(vc, animated: true)
    }
    
    func makeHomeFlow() -> UIViewController {
        let navigationController = NavigationController()
        let router = HorizontalRouter(navigationController: navigationController)
        let coordinator = HomeCoordinator(router: router)
        coordinator.start()
        return navigationController
    }
    
    func makeMapsFlow()-> UIViewController  {
        let navigationController = NavigationController()
        let router = HorizontalRouter(navigationController: navigationController)
        let coordinator = MapCoordinator(router: router, openMaps: openMaps)
        coordinator.start()
        return navigationController
    }
    
    func makeUserFlow() -> UIViewController {
        let navigationController = NavigationController()
        let router = HorizontalRouter(navigationController: navigationController)
        let coordinator = UserCoordinator(router: router)
        coordinator.start()
        return navigationController
    }
    
    func makePublishFlow() -> UIViewController  {
        let navigationController = NavigationController()
        let router = HorizontalRouter(navigationController: navigationController)
        let coordinator = PublishCoordinator(router: router)
        coordinator.start()
        return navigationController
    }
    
    func makeSearchFlow() -> UIViewController {
        let navigationController = NavigationController()
        let router = HorizontalRouter(navigationController: navigationController)
        let coordinator = SearchCoordinator(router: router)
        coordinator.start()
        return navigationController
    }
    
}
