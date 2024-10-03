import UIKit
import SwiftUI
import Combine


// MARK: Set Flows
private extension AppCoordinator {
    func setMainFlow() {
        let tabBarCoordinator = coordinatorFactory.makeTabBarCoordinator(path: path)
        self.push(tabBarCoordinator)
    }

    
    func showLogin() {
        let loginCoordinator = LoginCoordinator()
        self.push(loginCoordinator)
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
//        onboardingCoordinator.build()
//        window.setRootViewController(onboardingNVC)
    }
}


final class AppCoordinator: ObservableObject {
    @Published var path: NavigationPath
    private var cancellables = Set<AnyCancellable>()
    
    
    var coordinatorFactory: CoordinatorFactoryImpl = {
        return CoordinatorFactoryImpl()
    }()

    // MARK: - Stored Properties for redirections

    @ViewBuilder
    func build() -> some View {
        splashView()
    }
    
    init(path: NavigationPath) {
        self.path = path
    }
    
    private func push<T: Hashable>(_ coordinator: T) {
        path.append(coordinator)
    }
    
    
    private func splashView() -> some View {
        let coord = coordinatorFactory.makeSplash(actions: makeSplashActions())
        let splashView = coord.build()
        return splashView
    }
//
//    // MARK: Flow Control Methods
//    private func homeFlow() {
//        let usersFlowCoordinator = HomeCoordinator()
//        self.bind(userCoordinator: usersFlowCoordinator)
//        self.push(usersFlowCoordinator)
//    }
//    
//    private func searchFlow() {
//        let settingsFlowCoordinator = SearchCoordinator()
//        self.bind(settingsCoordinator: settingsFlowCoordinator)
//        self.push(settingsFlowCoordinator)
//    }
//    
//    private func publishFlow() {
//        let profileFlowCoordinator = PublishCoordinator()
//        self.bind(profileCoordinator: profileFlowCoordinator)
//        self.push(profileFlowCoordinator)
//    }
//    
//    private func mapFlow() {
//        let profileFlowCoordinator = ProfileFlowCoordinator(page: .main)
//        self.bind(profileCoordinator: profileFlowCoordinator)
//        self.push(profileFlowCoordinator)
//    }
//    
//    private func userFlow() {
//        let profileFlowCoordinator = ProfileFlowCoordinator(page: .main)
//        self.bind(profileCoordinator: profileFlowCoordinator)
//        self.push(profileFlowCoordinator)
//    }
    
}


private extension AppCoordinator {
    func makeSplashActions() -> SplashPresenterImpl.Actions {
        return .init(
            onMainFlow: setMainFlow,
            onLogin: showLogin
        )
    }
}
