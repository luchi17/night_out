import SwiftUI
import Combine

protocol TabViewPresenter {
    var viewModel: TabViewModel { get }
}

class TabViewModel: ObservableObject {
    
    @Published var selectedTab: TabType?
    @Published var viewToShow: AnyView?

    // MARK: - Lifecycle
    public init(selectedTab: TabType?) {
        self.selectedTab = selectedTab
    }
}


class TabViewPresenterImpl: TabViewPresenter {
    
    var viewModel: TabViewModel
    var openTab: (TabType) -> AnyView

    private var cancellables = Set<AnyCancellable>()
    
    init(
        viewModel: TabViewModel,
        openTab: @escaping (TabType) -> AnyView
    ) {
        self.viewModel = viewModel
        self.openTab = openTab
        
        viewModel
            .$selectedTab
            .removeDuplicates()
            .withUnretained(self)
            .sink { presenter, selectedTab in
                if let tab = selectedTab {
                    presenter.viewModel.viewToShow = openTab(tab)
                }
            }
            .store(in: &cancellables)
    }
}

