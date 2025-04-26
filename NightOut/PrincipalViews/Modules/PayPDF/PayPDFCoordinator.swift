import SwiftUI
import Combine

class PayPDFCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PayPDFCoordinator, rhs: PayPDFCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: PayPDFPresenterImpl.Actions
    private let model: PDFModel
    
    init(actions: PayPDFPresenterImpl.Actions, model: PDFModel) {
        self.actions = actions
        self.model = model
    }
    
    @ViewBuilder
    func build() -> some View {
        PayPDFView(presenter: PayPDFPresenterImpl(
            actions: actions,
            useCases: .init(),
            model: model
        ))
    }
}
