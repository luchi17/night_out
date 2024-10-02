import SwiftUI
import Combine

protocol TabViewPresenter {
    var openTab: InputClosure<TabType> { get }
    var viewModel: TabViewModel { get }
}

class TabViewModel: ObservableObject {
    
    public var selectedTab: TabType?

    // MARK: - Lifecycle
    public init(selectedTab: TabType?) {
        self.selectedTab = selectedTab
    }
    
    // Aquí puedes agregar más propiedades o métodos según sea necesario
    func selectTab(_ type: TabType) {
        selectedTab = type
    }
}


struct TabViewPresenterImpl: TabViewPresenter {
    
    var viewModel: TabViewModel
    var openTab: InputClosure<TabType>

    init(
        viewModel: TabViewModel,
        openTab: @escaping InputClosure<TabType>
    ) {
        self.viewModel = viewModel
        self.openTab = openTab
    }

    func onTapSelected(tabType: TabType) {
        openTab(tabType)
    }
}

