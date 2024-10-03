import SwiftUI
import Combine

final class LocationsMapViewModel: ObservableObject {

    init(
        
    ) {
    
    }
}

protocol LocationsMapPresenter {
    var viewModel: LocationsMapViewModel { get }
    func transform(input: LocationsMapPresenterImpl.ViewInputs)
}

final class LocationsMapPresenterImpl: LocationsMapPresenter {
    struct UseCases {
        
    }
    
    struct Actions {
        let onOpenMaps: InputClosure<(Double, Double)>
    }
    
    var viewModel: LocationsMapViewModel
    
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    struct ViewInputs {
        let openMaps: AnyPublisher<(Double, Double), Never>
    }
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = LocationsMapViewModel()
    }
    
    func transform(input: LocationsMapPresenterImpl.ViewInputs){
        input
            .openMaps
            .withUnretained(self)
            .sink { presenter, data in
                self.actions.onOpenMaps(data)
            }
            .store(in: &cancellables)
    }
    
}
