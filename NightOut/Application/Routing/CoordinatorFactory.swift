
import UIKit
import SwiftUI

final class CoordinatorFactoryImpl {
    
    init() { }
    
    func makeTabBarCoordinator(path: NavigationPath) -> TabViewCoordinator {
        return TabViewCoordinator(
            path: path,
            locationManager: LocationManager.shared,
            openMaps: openGoogleMaps(latitude:longitude:)
        )
    }
    
    func makeLogin() -> LoginCoordinator {
        return LoginCoordinator()
    }
    
    func makeSplash(actions: SplashPresenterImpl.Actions) -> SplashCoordinator {
        return SplashCoordinator(actions: actions)
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
