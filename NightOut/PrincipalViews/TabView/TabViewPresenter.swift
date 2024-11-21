import SwiftUI
import Combine

protocol TabViewPresenter {
    func onTapSelected(tabType: TabType)
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


struct TabViewPresenterImpl: TabViewPresenter {
    
    var viewModel: TabViewModel
    var openTab: (TabType) -> AnyView

    init(
        viewModel: TabViewModel,
        openTab: @escaping (TabType) -> AnyView
    ) {
        self.viewModel = viewModel
        self.openTab = openTab
        
        if let tab = viewModel.selectedTab {
            viewModel.viewToShow = openTab(tab)
        }
    }

    func onTapSelected(tabType: TabType) {
        viewModel.viewToShow = openTab(tabType)
    }
}

