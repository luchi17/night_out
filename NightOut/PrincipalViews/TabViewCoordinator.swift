import SwiftUI
import Combine

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
        openMaps: @escaping (Double, Double) -> Void
    ) {
        self.path = path
        self.openMaps = openMaps
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
        let coordinator = HomeCoordinator()
        return AnyView(coordinator.build())
    }
    
    func makeMapsFlow() -> AnyView {
        let coordinator = MapCoordinator(openMaps: openMaps)
        return AnyView(coordinator.build())
    }
    
    func makeUserFlow() -> AnyView {
        let coordinator = UserCoordinator()
        return AnyView(coordinator.build())
    }
    
    func makePublishFlow() -> AnyView {
        let coordinator = PublishCoordinator()
        return AnyView(coordinator.build())
        
    }
    
    func makeSearchFlow() -> AnyView {
        let coordinator = SearchCoordinator()
        return AnyView(coordinator.build())
    }
    
}
