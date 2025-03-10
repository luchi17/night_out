import UIKit
import SwiftUI
import Combine
import CoreLocation
import MapKit

//https://github.com/TharinduKetipe/MVVMC-SwiftUI/blob/main/Coordinator/Settings/SettingsFlowCoordinator.swift

final class AppCoordinator: ObservableObject {
    @Published var path: NavigationPath
    
    private let showMyProfileSubject = PassthroughSubject<Void, Never>()
    
    @ObservedObject var tabViewModel: TabViewModel
    
    // MARK: - Stored Properties for redirections
    
    @ViewBuilder
    func build() -> some View {
        splashView()
    }
    
    init(path: NavigationPath) {
        self.path = path
        self.tabViewModel = TabViewModel(selectedTab: .home)
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
            showMyProfileSubject: showMyProfileSubject,
            tabViewModel: tabViewModel,
            locationManager: LocationManager.shared,
            openMaps: openGoogleMaps(latitude:longitude:),
            openAppleMaps: openAppleMaps(coordinate:placeName:),
            goToLogin: { [weak self] in
                self?.pop()
            },
            showPostUserProfileView: showPostUserProfileView,
            onShowPostComments: showPostComments,
            showNotificationsView: showNotificationsView,
            showProfile: showProfile,
            openMessages: openMessages,
            showPrivateProfile: showPrivateProfile,
            openTinder: openTinder,
            openHub: openHub,
            openLeagueDetail: openLeagueDetail,
            openCreateLeague: openCreateLeague,
            openDiscotecaDetail: openDiscotecaDetail,
            openTicketDetail: openTicketDetail,
            openPDFPay: openPDFPay
        )
        self.push(tabBarCoordinator)
    }
    
    private func openTinder() {
        let tinderCoordinator = TinderCoordinator(actions: .init(goBack: { [weak self] in
            self?.pop()
        }, openProfile: { [weak self] in
            self?.pop()
            self?.showMyProfileSubject.send()
        }))
        
        self.push(tinderCoordinator)
    }
    
    private func openHub() {
        let hubCoordinator = HubCoordinator(actions: .init(openUrl: openUrl))
        self.push(hubCoordinator)
    }
    
    private func goToFriendsList(followerIds: [String]) {
        let friendsCoordinator = FriendsCoordinator(actions: .init(), followerIds: followerIds)
        self.push(friendsCoordinator)
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
        let messagesView = ChatCoordinator(actions: .init(goBack: {
            [weak self] in
            self?.pop()
        }), chat: chat)
        
        self.push(messagesView)
    }
    
    private func showPostUserProfileView(info: UserPostProfileInfo) {
        let postUserProfileView = UserPostProfileCoordinator(actions: .init(goToFriendsList: goToFriendsList), info: info)
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
            }, openConfig: { [weak self] in
                self?.pop()
                self?.tabViewModel.selectedTab = .home
                self?.showMyProfileSubject.send()
            }
           ),
            model: model
        )
        self.push(userProfileCoordinator)
    }
    
    private func showPrivateProfile(model: ProfileModel) {
        let userProfileCoordinator = PrivateUserProfileCoordinator(actions: .init(), model: model)
        self.push(userProfileCoordinator)
    }
    
    private func showPostDetail(post: NotificationModelForView) {
        let postDetailCoordinator = PostDetailCoordinator(
            actions: .init(openComments: showPostComments),
            post: post
        )
        self.push(postDetailCoordinator)
    }
    
    private func showForgotPassword() {
        let forgotPasswordCoordinator = ForgotPasswordCoordinator()
        self.push(forgotPasswordCoordinator)
    }
    
    private func openLeagueDetail(league: League) {
        let leagueCoordinator = LeagueDetailCoordinator(actions: .init(goBack: { [weak self] in
            self?.pop()
        }), league: league)
        self.push(leagueCoordinator)
    }
    
    private func openCreateLeague() {
        let createLeagueCoordinator = CreateLeagueCoordinator(actions: .init(goBack: { [weak self] in
            self?.pop()
        }))
        self.push(createLeagueCoordinator)
    }
    
    private func openDiscotecaDetail(model: (CompanyModel, [Fiesta])) {
        let discotecaDetailCoordinator = DiscotecaDetailCoordinator(
            actions: .init(goBack: { [weak self] in
                self?.pop()
            }),
            model: model
        )
        self.push(discotecaDetailCoordinator)
    }
    
    private func openTicketDetail(model: (CompanyModel, Fiesta)) {
        let ticketDetailCoordinator = TicketDetailCoordinator(actions: .init(
            goBack: { [weak self] in
                self?.pop()
            },
            onOpenMaps: { [weak self] data in
                self?.openGoogleMaps(latitude: data.0, longitude: data.1)
            },
            onOpenAppleMaps: { [weak self] data in
                self?.openAppleMaps(coordinate: data.0, placeName: data.1)
            },
            openTicketInfoPay: openPayTicket
        ),
        model: model)
        
        self.push(ticketDetailCoordinator)
    }
    
    private func openPayTicket(model: PayDetailModel) {
        let ticketPayCoordinator = PayDetailCoordinator(actions: .init(goBack: { [weak self] in
            self?.pop()
        },openPDFPay: openPDFPay, navigateToHome: { [weak self] in
            self?.pop()
            self?.pop()
        }),
         model: model
        )
        self.push(ticketPayCoordinator)
    }
    
    private func openPDFPay(model: PDFModel) {
        let payPDFCoordinator = PayPDFCoordinator(actions: .init(
            goBack: { [weak self] in
                self?.pop()
                self?.pop()
                self?.pop()
            }
        ), model: model)
        self.push(payPDFCoordinator)
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
            goToRegisterCompany: showRegisterCompanyView,
            goToForgotPassword: showForgotPassword
        )
    }
    
    func makeRegisterUserActions() -> SignupPresenterImpl.Actions {
        return .init(
            goToTabView: {
                self.pop()
                self.showTabView()
            },
            backToLogin: {
                [weak self] in
                self?.pop()
            }
        )
    }
    
    func makeRegisterCompanyActions() -> SignupCompanyPresenterImpl.Actions {
        return .init(
            goToTabView: {
                self.pop()
                self.showTabView()
            },
            backToLogin: {
                [weak self] in
                self?.pop()
            }
        )
    }
    
    func makeNotificationsActions() -> NotificationsPresenterImpl.Actions {
        return .init(
            goToProfile: showProfile(model:),
            goToPrivateProfile: showPrivateProfile(model:),
            goToPost: showPostDetail
        )
    }
    
    func makeMessagesActions() -> MessagesPresenterImpl.Actions {
        return .init(
            goToChat: openChat,
            goBack: {
                [weak self] in
                self?.pop()
            }
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
    
    func openUrl(urlString: String) {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
