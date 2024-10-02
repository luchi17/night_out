import SwiftUI

@main
struct NighOutApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appCoordinator = AppCoordinator(window: <#Window#>)
    
    let homeCoordinator = appDelegate.appCoordinator.
    
    
    var body: some Scene {
        WindowGroup {
            
        }
    }
}
