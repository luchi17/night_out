import SwiftUI
import Combine


final class HubViewModel: ObservableObject {
   
    
    @Published var toast: ToastType?
    @Published var gameTapped: GameType?
    @Published var loading: Bool = false
    
    init() {
        
    }
}

protocol HubPresenter {
    var viewModel: HubViewModel { get }
    func transform(input: HubPresenterImpl.ViewInputs)
}

final class HubPresenterImpl: HubPresenter {
    
    struct UseCases {
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
//        let saveInfo: AnyPublisher<Void, Never>
//        let logout: AnyPublisher<Void, Never>
    }
    
    var viewModel: HubViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases

        viewModel = HubViewModel()
    }
    
    func transform(input: HubPresenterImpl.ViewInputs) {
        
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
               
            }
            .store(in: &cancellables)
        
      
    }


}

extension HubPresenterImpl {

}


