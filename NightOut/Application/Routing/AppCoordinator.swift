import UIKit
import SwiftUI

final class Window: UIWindow {
    func setRootViewController(_ vc: UIViewController) {
        rootViewController = vc
    }
}

class AppCoordinator: ObservableObject {
    
    @Published var path = NavigationPath()
    
    let window: Window
    
    init(
        window: Window
    ) {
        self.window = window
    }

    // MARK: - Stored Properties for redirections

    @MainActor func start() {
        self.setMainFlow()
//        self.setSplashViewController()
    }
}

// MARK: Set Flows
private extension AppCoordinator {
    @MainActor
    func setMainFlow() {
        let tabBarNVC = NavigationController()
        tabBarNVC.setNavigationBarHidden(true, animated: false)
       
        let tabBarCoordinator = CoordinatorFactoryImpl().makeTabBarCoordinator(
            router: HorizontalRouter(navigationController: tabBarNVC, onCloseButtonTap: nil),
            selectedTab: nil
        )
        tabBarCoordinator.start()

        window.setRootViewController(tabBarNVC)
        
        path.append(tabBarNVC)

    }

    func setSplashViewController() {
//        let splashViewController = moduleFactory.makeSplashScreen(
//            actions: makeSplashActions()
//        )
//        window.setRootViewController(splashViewController)
    }

    func navigateToOnboardingFlow() {
//        let onboardingNVC = NavigationController()
//        let router = HorizontalRouter(
//            navigationController: onboardingNVC
//        )
//
//        let onboardingCoordinator = coordinatorFactory.makeOnboardingCoordinator(
//            router: router,
//            onCompletion: setMainFlow
//        )
//        onboardingCoordinator.start()
//        window.setRootViewController(onboardingNVC)
    }
}

private extension AppCoordinator {
//    func makeSplashActions() -> SplashPresenterImpl.Actions {
//        return .init(
//            onMainFlow: setMainFlow,
//            onOnboardingFlow: navigateToOnboardingFlow,
//            onUpdateApplication: openAppstoreToUpdateApplication
//        )
//    }
}

