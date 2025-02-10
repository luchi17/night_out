import UIKit
import SwiftUI
import Combine
import CoreLocation
import MapKit

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
            openAppleMaps: openAppleMaps(coordinate:placeName:),
            goToLogin: {
                self.pop()
            },
            showPostUserProfileView: showPostUserProfileView,
            onShowPostComments: showPostComments,
            showNotificationsView: showNotificationsView,
            showProfile: showProfile(model:),
            openMessages: openMessages
        )
        self.push(tabBarCoordinator)
    }
    
    private func showNotificationsView() {
        let notificationsView = NotificationsCoordinator(actions: makeNotificationsActions())
        self.push(notificationsView)
    }
    
    private func openMessages() {
        let messagesView = MessagesCoordinator(actions: makeMessagesActions())
        self.push(messagesView)
    }
    
    private func openChat(chat: Chat) {
        let messagesView = ChatCoordinator(actions: .init(goBack: self.pop), chat: chat)
        self.push(messagesView)
    }
    
    private func showPostUserProfileView(info: UserPostProfileInfo) {
        let postUserProfileView = UserPostProfileCoordinator(actions: .init(), info: info)
        self.push(postUserProfileView)
    }
    
    private func showRegisterUserView() {
        let signupCoordinator = SignupCoordinator(actions: makeRegisterUserActions())
        self.push(signupCoordinator)
    }
    
    private func showRegisterCompanyView() {
        let signupCoordinator = SignUpCompanyCoordinator(actions: makeRegisterCompanyActions())
        self.push(signupCoordinator)
    }
    
    private func showPostComments(info: PostCommentsInfo) {
        let commentsCoordinator = CommentsCoordinator(actions: .init(), info: info)
        self.push(commentsCoordinator)
    }
    
    private func showLogin() {
        let loginCoordinator = LoginCoordinator(actions: makeLoginActions())
        self.push(loginCoordinator)
    }
    
    private func showProfile(model: ProfileModel) {
        let userProfileCoordinator = UserProfileCoordinator(
            actions: .init(goBack: { [weak self] in
                self?.pop()
            }, openAnotherProfile: { [weak self] profile in
                self?.showProfile(model: profile)
            }),
            model: model
        )
        self.push(userProfileCoordinator)
    }
    
    private func showPostDetail(post: NotificationModelForView) {
        let postDetailCoordinator = PostDetailCoordinator(
            actions: .init(openComments: showPostComments),
            post: post
        )
        self.push(postDetailCoordinator)
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
            goToTabView: {
                self.pop()
                self.showTabView()
            },
            backToLogin: self.pop
        )
    }
    
    func makeRegisterCompanyActions() -> SignupCompanyPresenterImpl.Actions {
        return .init(
            goToTabView: {
                self.pop()
                self.showTabView()
            },
            backToLogin: self.pop
        )
    }
    
    func makeNotificationsActions() -> NotificationsPresenterImpl.Actions {
        return .init(
            goToProfile: showProfile(model:),
            goToPost: showPostDetail
        )
    }
    
    func makeMessagesActions() -> MessagesPresenterImpl.Actions {
        return .init(
            goToChat: openChat,
            goBack: self.pop
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
    
    private func openAppleMaps(coordinate: CLLocationCoordinate2D, placeName: String?) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = placeName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    static func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "Version \(version) (Build \(build))"
        }
        return "Version not found"
    }
}
