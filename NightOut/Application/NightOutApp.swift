import SwiftUI

@main
struct NighOutApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
            WindowGroup {
                ContentView()
            }
        }
}

struct ContentView: View {
    @StateObject private var appCoordinator = AppCoordinator(path: NavigationPath())
    
    var body: some View {
        NavigationStack(path: $appCoordinator.path) {
            appCoordinator.build()
                .navigationDestination(for: LoginCoordinator.self, destination: { coordinator in
                    coordinator.build()
                })
                .navigationDestination(for: TabViewCoordinator.self, destination: { coordinator in
                    coordinator.build()
                })
               
//                .navigationDestination(for: HomeCoordinator.self) { coordinator in
////                    coordinator.build()
//                }
//                .navigationDestination(for: SearchCoordinator.self) { coordinator in
//                    coordinator.build()
//                }
//                .navigationDestination(for: PublishCoordinator.self) { coordinator in
//                    coordinator.build()
//                }
//                .navigationDestination(for: MapCoordinator.self) { coordinator in
//                    coordinator.build()
//                }
//                .navigationDestination(for: UserCoordinator.self) { coordinator in
//                    coordinator.build()
//                }

        }
        .environmentObject(appCoordinator)
    }
}
