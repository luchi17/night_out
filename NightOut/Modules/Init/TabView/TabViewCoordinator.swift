import SwiftUI
import Combine
import CoreLocation

enum TabType: Equatable {
    case home
    case search
    case publish
    case leagues
    case calendar
    
    public static func == (lhs: TabType, rhs: TabType) -> Bool {
        switch(lhs, rhs) {
        case (.home, .home), (.search, .search), (.publish, .publish), (.leagues, .leagues), (.calendar, .calendar):
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
    private let openLeagueDetail: InputClosure<League>
    private let openCreateLeague: VoidClosure
    private let openDiscotecaDetail: InputClosure<(CompanyModel, [Fiesta])>
    private let openTicketDetail: InputClosure<(CompanyModel, Fiesta)>
    private let openPDFPay: InputClosure<PDFModel>
    private let openHistoryTickets: VoidClosure
    
    private let locationManager: LocationManager
    private let showMyProfileSubject: PassthroughSubject<Void, Never>
    
    private let reloadFeedSubject = PassthroughSubject<Void, Never>()

    private lazy var homeCoordinator: HomeCoordinator = getHomeCoordinator()
    private lazy var searchCoordinator: SearchCoordinator = getSearchCoordinator()
    private lazy var publishCoordinator: PublishCoordinator = getPublishCoordinator()
    private lazy var leaguesCoordinator: LeagueCoordinator = getLeaguesCoordinator()
    private lazy var ticketsCoordinator: TicketsCoordinator = getTicketsCoordinator()

    private lazy var homeView: AnyView = AnyView(homeCoordinator.build())
    private lazy var searchView: AnyView = AnyView(searchCoordinator.build())
    private lazy var publishView: AnyView = AnyView(publishCoordinator.build())
    private lazy var leaguesView: AnyView = AnyView(leaguesCoordinator.build())
    private lazy var ticketsView: AnyView = AnyView(ticketsCoordinator.build())
    
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
        openHub: @escaping VoidClosure,
        openLeagueDetail: @escaping InputClosure<League>,
        openCreateLeague: @escaping VoidClosure,
        openDiscotecaDetail: @escaping InputClosure<(CompanyModel, [Fiesta])>,
        openTicketDetail: @escaping InputClosure<(CompanyModel, Fiesta)>,
        openPDFPay: @escaping InputClosure<PDFModel>,
        openHistoryTickets: @escaping VoidClosure
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
        self.openLeagueDetail = openLeagueDetail
        self.openCreateLeague = openCreateLeague
        self.openDiscotecaDetail = openDiscotecaDetail
        self.openTicketDetail = openTicketDetail
        self.openPDFPay = openPDFPay
        self.openHistoryTickets = openHistoryTickets
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = TabViewPresenterImpl(viewModel: tabViewModel) { [weak self] selectedTab in
            guard let self = self else { return AnyView(EmptyView()) }
            switch selectedTab {
            case .home:
                return self.homeView
            case .search:
                return self.searchView
            case .publish:
                return self.publishView
            case .leagues:
                return self.leaguesView
            case .calendar:
                return self.ticketsView
            }
        }
        TabViewScreen(presenter: presenter)
    }
}

private extension TabViewCoordinator {
    func mapActions() -> LocationsMapPresenterImpl.Actions {
        .init(
            onOpenMaps: openMaps,
            onOpenAppleMaps: openAppleMaps,
            goToProfile: showProfile,
            goToPrivateProfile: showPrivateProfile
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
                self?.tabViewModel.selectedTab = .calendar
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
    
    func getHomeCoordinator() -> HomeCoordinator {
        let homeCoordinator = HomeCoordinator(
            actions: homeActions(),
            mapActions: mapActions(),
            feedActions: feedActions(),
            profileActions: profileActions(),
            locationManager: locationManager,
            showMyProfileSubject: showMyProfileSubject,
            reloadFeedSubject: reloadFeedSubject
        )
        return homeCoordinator
    }
    
    func getSearchCoordinator() -> SearchCoordinator {
        return SearchCoordinator(actions: searchActions())
    }
    
    func getPublishCoordinator() -> PublishCoordinator {
        return PublishCoordinator(actions: .init(goToFeed: { [weak self] in
            self?.tabViewModel.selectedTab = .home
        }))
    }
    
    func getLeaguesCoordinator() -> LeagueCoordinator {
        return LeagueCoordinator(actions: .init(
            goToCreateLeague: openCreateLeague,
            goToLeagueDetail: openLeagueDetail
        ))
    }
    
    func getTicketsCoordinator() -> TicketsCoordinator {
        return TicketsCoordinator(actions: .init(
            goToCompany: openDiscotecaDetail,
            goToEvent: openTicketDetail,
            openHistoryTickets: openHistoryTickets
        ))
    }
}
