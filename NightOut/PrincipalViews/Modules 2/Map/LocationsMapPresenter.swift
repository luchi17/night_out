import SwiftUI
import Combine

final class LocationsMapViewModel: ObservableObject {

    init(
        
    ) {
    
    }
}

protocol LocationsMapPresenter {
    var viewModel: LocationsMapViewModel { get }
    var input: LocationsMapPresenterImpl.ViewInputs { get }
}

final class LocationsMapPresenterImpl: LocationsMapPresenter {
    struct UseCases {
        
    }

    struct Actions {
        let onOpenMaps: InputClosure<(Double, Double)>
    }

    var viewModel: LocationsMapViewModel

    let input: ViewInputs

    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()

    struct ViewInputs {
        
    }

    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases

        viewModel = LocationsMapViewModel()

        input = ViewInputs()
        transform()
    }

    func transform() {
    }
       
