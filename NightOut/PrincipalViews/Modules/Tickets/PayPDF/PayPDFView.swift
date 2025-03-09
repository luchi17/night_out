import SwiftUI
import Combine

struct PayPDFView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    private let pagarPublisher = PassthroughSubject<Void, Never>()
    
    
    @ObservedObject var viewModel: PayPDFViewModel
    let presenter: PayPDFPresenter
    
    init(
        presenter: PayPDFPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
           
        }
        .background(
            Color.blackColor
        )
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: viewModel.loading
        )
        .onAppear(perform: viewDidLoadPublisher.send)
    }
}

private extension PayPDFView {
    
    func bindViewModel() {
        let input = PayPDFPresenterImpl.Input(
            viewIsLoaded: viewDidLoadPublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher(),
            pagar: pagarPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }

}
