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
            appCoordinator
                .build()
                .navigationDestination(for: LoginCoordinator.self, destination: { coordinator in
                    coordinator
                        .build()
                        .navigationDestination(for: SignupCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
                        .navigationDestination(for: SignUpCompanyCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
                })
                .navigationDestination(for: TabViewCoordinator.self, destination: { coordinator in
                    coordinator
                        .build()
                        .edgesIgnoringSafeArea(.top)
                        .navigationDestination(for: CommentsCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
                        .navigationDestination(for: UserPostProfileCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
                        .navigationDestination(for: NotificationsCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                                .navigationDestination(for: UserProfileCoordinator.self) { coordinator in
                                    coordinator
                                        .build()
                                        .showCustomBackButtonNavBar()
                                }
                                .navigationDestination(for: PostDetailCoordinator.self) { coordinator in
                                    coordinator
                                        .build()
                                        .showCustomBackButtonNavBar()
                                }
                        }
                        .navigationDestination(for: UserProfileCoordinator.self) { coordinator in
                            coordinator
                                .build()
                        }
                        .navigationDestination(for: MessagesCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .navigationDestination(for: ChatCoordinator.self) { coordinator in
                                    coordinator
                                        .build()
                                }
                        }
                })
        }
        .environmentObject(appCoordinator)
    }
}

class AppState: ObservableObject {
    static let shared = AppState()
    @Published var isUserLoggedIn: Bool = false
    @Published var shouldShowSplash: Bool = true

    private init() {}

    func logOut() {
        isUserLoggedIn = false
        shouldShowSplash = false // Evita mostrar el Splash después de logout
    }

    func logIn() {
        isUserLoggedIn = true
        shouldShowSplash = true
    }
}
