import SwiftUI
import AVKit

@main
struct NighOutApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // permite que el video se reproduzca sin interrumpir otros audios en reproducción.
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error configurando sesión de audio: \(error.localizedDescription)")
        }
    }
    
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
                        .navigationDestination(for: ForgotPasswordCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
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
                        .navigationDestination(for: HubCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
                        .navigationDestination(for: TinderCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
                        .navigationDestination(for: CommentsCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
                        .navigationDestination(for: UserPostProfileCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                                .navigationDestination(for: FriendsCoordinator.self) { coordinator in
                                    coordinator
                                        .build()
                                        .showCustomBackButtonNavBar()
                                }
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
                        .navigationDestination(for: PrivateUserProfileCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
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
                        .navigationDestination(for: LeagueDetailCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
                        .navigationDestination(for: CreateLeagueCoordinator.self) { coordinator in
                            coordinator
                                .build()
                                .showCustomBackButtonNavBar()
                        }
                        .navigationDestination(for: DiscotecaDetailCoordinator.self) { coordinator in
                            coordinator
                                .build()
                        }
                        .navigationDestination(for: TicketDetailCoordinator.self) { coordinator in
                            coordinator
                                .build()
                        }
                })
        }
        .environmentObject(appCoordinator)
        .environmentObject(AppState.shared)
    }
}

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var shouldShowSplashVideo: Bool = true
    
    private init() {}
}
