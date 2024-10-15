import UIKit
import SwiftUI
import Combine

//https://github.com/TharinduKetipe/MVVMC-SwiftUI/blob/main/Coordinator/Settings/SettingsFlowCoordinator.swift

final class AppCoordinator: ObservableObject {
    @Published var path: NavigationPath
    
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
    
    private func pop() {
        path.removeLast()
    }
    
    
    private func splashView() -> some View {
        let coord = coordinatorFactory.makeSplash(actions: makeSplashActions())
        let splashView = coord.build()
        return splashView
    }
    
    private func showTabView() {
        let tabBarCoordinator = coordinatorFactory.makeTabBarCoordinator(path: path)
        self.push(tabBarCoordinator)
    }
    
    private func showRegisterUserView() {
        let signupCoordinator = coordinatorFactory.makeRegister(actions: makeRegisterActions())
        self.push(signupCoordinator)
    }
    
    private func showLogin() {
        let loginCoordinator = coordinatorFactory.makeLogin(actions: makeLoginActions())
        self.push(loginCoordinator)
    }
    
}

private extension AppCoordinator {
    func makeSplashActions() -> SplashPresenterImpl.Actions {
        return .init(
            onMainFlow: showTabView,
            onLogin: showLogin
        )
    }
    
    func makeLoginActions() -> LoginPresenterImpl.Actions {
        return .init(
            goToTabView: showTabView,
            goToRegisterUser: showRegisterUserView
        )
    }
    
    func makeRegisterActions() -> SignupPresenterImpl.Actions {
        return .init(
            goToTabView: showTabView,
            backToLogin: self.pop
        )
    }
}

extension AppCoordinator {
    static func getRootViewController() -> UIViewController {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("No root view controller found")
        }
        return rootViewController
    }
}
