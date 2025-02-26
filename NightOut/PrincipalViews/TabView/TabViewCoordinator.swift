import SwiftUI
import Combine
import CoreLocation

enum TabType: Equatable {
    case home
    case search
    case publish
    case map
    case user
    
    public static func == (lhs: TabType, rhs: TabType) -> Bool {
        switch(lhs, rhs) {
        case (.home, .home), (.search, .search), (.publish, .publish), (.map, .map), (.user, .user):
            return true
        default:
            return false
        }
    }
}

class TabViewCoordinator: ObservableObject, Hashable {
    
    private let openMaps: (Double, Double) -> Void
    private let openAppleMaps: (CLLocationCoordinate2D, String?) -> Void
    private let onShowPostComments: InputClosure<PostCommentsInfo>
    private let goToLogin: VoidClosure
    private let showPostUserProfileView: InputClosure<UserPostProfileInfo>
    private let showNotificationsView: VoidClosure
    private let showProfile: InputClosure<ProfileModel>
    private let showPrivateProfile: InputClosure<ProfileModel>
    private let openMessages: VoidClosure
    private let openTinder: VoidClosure
    private let openHub: VoidClosure
    
    private let locationManager: LocationManager
    private let showMyProfileSubject: PassthroughSubject<Void, Never>
    
    @Published var path: NavigationPath
    @ObservedObject var tabViewModel: TabViewModel
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TabViewCoordinator, rhs: TabViewCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(
        path: NavigationPath,
        showMyProfileSubject: PassthroughSubject<Void, Never>,
        tabViewModel: TabViewModel,
        locationManager: LocationManager,
        openMaps: @escaping (Double, Double) -> Void,
        openAppleMaps: @escaping (CLLocationCoordinate2D, String?) -> Void,
        goToLogin: @escaping VoidClosure,
        showPostUserProfileView: @escaping InputClosure<UserPostProfileInfo>,
        onShowPostComments:  @escaping InputClosure<PostCommentsInfo>,
        showNotificationsView: @escaping VoidClosure,
        showProfile: @escaping InputClosure<ProfileModel>,
        openMessages: @escaping VoidClosure,
        showPrivateProfile: @escaping InputClosure<ProfileModel>,
        openTinder: @escaping VoidClosure,
        openHub: @escaping VoidClosure
    ) {
        self.path = path
        self.showMyProfileSubject = showMyProfileSubject
        self.tabViewModel = tabViewModel
        self.locationManager = locationManager
        self.openMaps = openMaps
        self.openAppleMaps = openAppleMaps
        self.goToLogin = goToLogin
        self.showPostUserProfileView = showPostUserProfileView
        self.onShowPostComments = onShowPostComments
        self.showNotificationsView = showNotificationsView
        self.showProfile = showProfile
        self.showPrivateProfile = showPrivateProfile
        self.openMessages = openMessages
        self.openTinder = openTinder
        self.openHub = openHub
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = TabViewPresenterImpl(viewModel: tabViewModel) { [weak self] selectedTab in
            guard let self = self else { return AnyView(EmptyView()) }
            switch selectedTab {
            case .home:
                return self.makeHomeFlow()
            case .search:
                return self.makeSearchFlow()
            case .publish:
                return self.makePublishFlow()
            case .map:
                return self.makeMapsFlow()
            case .user:
                return self.makeUserFlow()
            }
        }
        TabViewScreen(presenter: presenter)
    }
    
    func makeHomeFlow() -> AnyView {
        let coordinator = HomeCoordinator(
            actions: homeActions(),
            mapActions: mapActions(),
            feedActions: feedActions(),
            profileActions: profileActions(),
            locationManager: locationManager,
            showMyProfileSubject: showMyProfileSubject
        )
        return AnyView(coordinator.build())
    }
    
    func makeSearchFlow() -> AnyView {
        let coordinator = SearchCoordinator(actions: searchActions())
        return AnyView(coordinator.build())
    }
    
    func makePublishFlow() -> AnyView {
        let coordinator = PublishCoordinator(actions: .init(goToFeed: { [weak self] in
            self?.tabViewModel.selectedTab = .home
        }))
        return AnyView(coordinator.build())
    }
    
    func makeMapsFlow() -> AnyView {
        return AnyView(EmptyView())
    }
    
    func makeUserFlow() -> AnyView {
        let coordinator = TicketsCoordinator(actions: .init(backToLogin: { [weak self] in
            self?.goToLogin()
        }))
        return AnyView(coordinator.build())
    }
}

private extension TabViewCoordinator {
    func mapActions() -> LocationsMapPresenterImpl.Actions {
        .init(
            onOpenMaps: openMaps,
            onOpenAppleMaps: openAppleMaps
        )
    }
    
    func homeActions() -> HomePresenterImpl.Actions {
        .init(
            onOpenNotifications: showNotificationsView,
            openMessages: openMessages,
            openHub: openHub,
            openTinder: openTinder
        )
    }
    
    func feedActions() -> FeedPresenterImpl.Actions {
        .init(
            onOpenMaps: openMaps,
            onOpenAppleMaps: openAppleMaps,
            onShowUserProfile: showPostUserProfileView,
            onShowPostComments: onShowPostComments,
            onOpenCalendar: { [weak self] in
                self?.tabViewModel.selectedTab = .user
            }
        )
    }
    
    func profileActions() -> MyUserProfilePresenterImpl.Actions {
        .init(backToLogin: goToLogin)
    }
    
    func searchActions() -> SearchPresenterImpl.Actions {
        .init(
            goToProfile: showProfile,
            goToPrivateProfile: showPrivateProfile
        )
    }
}
