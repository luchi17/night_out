import SwiftUI
import Combine

enum HomeSelectedTab {
    case feed
    case map
    
    var title: String {
        switch self {
        case .feed:
            return "feed"
        case .map:
            return "mapa"
        }
    }
}


final class HomeViewModel: ObservableObject {
    @Published var selectedTab: HomeSelectedTab = .feed
}

protocol HomePresenter {
    var viewModel: HomeViewModel { get }
    func transform(input: HomePresenterImpl.ViewInputs)
}

final class HomePresenterImpl: HomePresenter {
    
    struct UseCases {
        
    }
    
    struct Actions {
        let onOpenProfile: VoidClosure
        let onOpenNotifications: VoidClosure
    }
    
    struct ViewInputs {
        let openProfile: AnyPublisher<Void, Never>
        let openNotifications: AnyPublisher<Void, Never>
    }
    
    var viewModel: HomeViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = HomeViewModel()
    }
    
    func transform(input: HomePresenterImpl.ViewInputs){
        input
            .openProfile
            .withUnretained(self)
            .sink { presenter in
                self.actions.onOpenProfile()
            }
            .store(in: &cancellables)
        
        input
            .openNotifications
            .withUnretained(self)
            .sink { presenter in
                self.actions.onOpenNotifications()
            }
            .store(in: &cancellables)
            
    }
}
