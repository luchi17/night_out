import Combine
import SwiftUI
import Firebase
import CoreLocation

struct PDFModel {
    let nameEvent: String
    let date: String
    let companyuid: String
    let quantity: Int
    let personDataList: [PersonTicketData]
    
    init(nameEvent: String, date: String, companyuid: String, quantity: Int, personDataList: [PersonTicketData]) {
        self.nameEvent = nameEvent
        self.date = date
        self.companyuid = companyuid
        self.quantity = quantity
        self.personDataList = personDataList
    }
}

class PayPDFViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var model: PDFModel
    
    init(model: PDFModel) {
        self.model = model
    }
}

protocol PayPDFPresenter {
    var viewModel: PayPDFViewModel { get }
    func transform(input: PayPDFPresenterImpl.Input)
}

final class PayPDFPresenterImpl: PayPDFPresenter {
    var viewModel: PayPDFViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
        let pagar: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
        
    }
    
    struct Actions {
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()

    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases, model: PDFModel) {
        
        self.viewModel = PayPDFViewModel(model: model)
        self.actions = actions
        self.useCases = useCases

    }
    
    func transform(input: Input) {
        
        input
            .viewIsLoaded
            .withUnretained(self)
            .sink { presenter, _ in
               
            }
            .store(in: &cancellables)
        
        
        input
            .pagar
            .withUnretained(self)
            .sink { presenter, _ in
               
            }
            .store(in: &cancellables)
        
    }
}
