import UIKit
import SwiftUI
import Combine

//https://github.com/TharinduKetipe/MVVMC-SwiftUI/blob/main/Coordinator/Settings/SettingsFlowCoordinator.swift

final class AppCoordinator: ObservableObject {
    @Published var path: NavigationPath

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
        let coord = SplashCoordinator(actions: makeSplashActions())
        let splashView = coord.build()
        return splashView
    }
    
    private func showTabView() {
        let tabBarCoordinator = TabViewCoordinator(
            path: path,
            locationManager: LocationManager.shared,
            openMaps: openGoogleMaps(latitude:longitude:),
            goToLogin: {
                self.pop()
                self.showLogin()
            }
        )
        self.push(tabBarCoordinator)
    }
    
    private func showRegisterUserView() {
        let signupCoordinator = SignupCoordinator(actions: makeRegisterUserActions())
        self.push(signupCoordinator)
    }
    
    private func showRegisterCompanyView() {
        let signupCoordinator = SignUpCompanyCoordinator(actions: makeRegisterCompanyActions())
        self.push(signupCoordinator)
    }
    
    private func showLogin() {
        let loginCoordinator = LoginCoordinator(actions: makeLoginActions())
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
            goToRegisterUser: showRegisterUserView,
            goToRegisterCompany: showRegisterCompanyView
        )
    }
    
    func makeRegisterUserActions() -> SignupPresenterImpl.Actions {
        return .init(
            goToTabView: showTabView,
            backToLogin: self.pop
        )
    }
    
    func makeRegisterCompanyActions() -> SignupCompanyPresenterImpl.Actions {
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
    
    func openGoogleMaps(latitude: Double, longitude: Double) {
            let urlString = "comgooglemaps://?q=\(latitude),\(longitude)"
            if let url = URL(string: urlString) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    // Fallback to open in Safari if Google Maps is not installed
                    let browserUrl = URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)")!
                    UIApplication.shared.open(browserUrl, options: [:], completionHandler: nil)
                }
            }
        }
}
