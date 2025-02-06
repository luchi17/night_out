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
    private let openMessages: VoidClosure
    private let locationManager: LocationManager
    
    @Published var path: NavigationPath
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TabViewCoordinator, rhs: TabViewCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(
        path: NavigationPath,
        locationManager: LocationManager,
        openMaps: @escaping (Double, Double) -> Void,
        openAppleMaps: @escaping (CLLocationCoordinate2D, String?) -> Void,
        goToLogin: @escaping VoidClosure,
        showPostUserProfileView: @escaping InputClosure<UserPostProfileInfo>,
        onShowPostComments:  @escaping InputClosure<PostCommentsInfo>,
        showNotificationsView: @escaping VoidClosure,
        showProfile: @escaping InputClosure<ProfileModel>,
        openMessages: @escaping VoidClosure
    ) {
        self.path = path
        self.locationManager = locationManager
        self.openMaps = openMaps
        self.openAppleMaps = openAppleMaps
        self.goToLogin = goToLogin
        self.showPostUserProfileView = showPostUserProfileView
        self.onShowPostComments = onShowPostComments
        self.showNotificationsView = showNotificationsView
        self.showProfile = showProfile
        self.openMessages = openMessages
    }
    
    @ViewBuilder
    func build() -> some View {
        let viewModel = TabViewModel(selectedTab: .home)
        let presenter = TabViewPresenterImpl(viewModel: viewModel) { selectedTab in
            switch selectedTab {
            case .home:
                self.makeHomeFlow()
            case .search:
                self.makeSearchFlow()
            case .publish:
                self.makePublishFlow()
            case .map:
                self.makeMapsFlow()
            case .user:
                self.makeUserFlow()
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
            locationManager: locationManager
        )
        return AnyView(coordinator.build())
    }
    
    func makeSearchFlow() -> AnyView {
        let coordinator = SearchCoordinator(actions: searchActions())
        return AnyView(coordinator.build())
    }
    
    func makePublishFlow() -> AnyView {
        let coordinator = PublishCoordinator(actions: .init())
        return AnyView(coordinator.build())
        
    }
    
    #warning("REDO")
    func makeMapsFlow() -> AnyView {
        return AnyView(EmptyView())
    }
    
    func makeUserFlow() -> AnyView {
        let coordinator = TicketsCoordinator(actions: .init(backToLogin: {
            self.goToLogin()
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
            openMessages: openMessages
        )
    }
    
    func feedActions() -> FeedPresenterImpl.Actions {
        .init(
            onOpenMaps: openMaps,
            onOpenAppleMaps: openAppleMaps,
            onShowUserProfile: showPostUserProfileView,
            onShowCompanyProfile: { _ in },
            onShowPostComments: onShowPostComments
        )
    }
    
    func profileActions() -> MyUserProfilePresenterImpl.Actions {
        .init(backToLogin: goToLogin)
    }
    
    func searchActions() -> SearchPresenterImpl.Actions {
        .init(goToProfile: showProfile)
    }
}
