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
    @Published var profileImageUrl: String?
}

protocol HomePresenter {
    var viewModel: HomeViewModel { get }
    func transform(input: HomePresenterImpl.ViewInputs)
}

final class HomePresenterImpl: HomePresenter {
    
    struct UseCases {
        
    }
    
    struct Actions {
        let onOpenNotifications: VoidClosure
        let openMessages: VoidClosure
    }
    
    struct ViewInputs {
        let openNotifications: AnyPublisher<Void, Never>
        let openMessages: AnyPublisher<Void, Never>
        let viewDidLoad: AnyPublisher<Void, Never>
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
            .openNotifications
            .withUnretained(self)
            .sink { presenter in
                self.actions.onOpenNotifications()
            }
            .store(in: &cancellables)
        
        input
            .openMessages
            .withUnretained(self)
            .sink { presenter in
                self.actions.openMessages()
            }
            .store(in: &cancellables)

        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                let imUser = FirebaseServiceImpl.shared.getImUser()
                if imUser {
                    presenter.viewModel.profileImageUrl =  UserDefaults.getUserModel()?.image
                } else {
                    presenter.viewModel.profileImageUrl =  UserDefaults.getCompanyUserModel()?.imageUrl
                }
            }
            .store(in: &cancellables)
    }
}
