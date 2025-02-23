
import SwiftUI
import Combine

struct LeagueView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let searchPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: LeagueViewModel
    let presenter: LeaguePresenter
    
    init(
        presenter: LeaguePresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            
            Spacer()
        }
        .background(
            Color.black
                .edgesIgnoringSafeArea(.top)
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
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
}

private extension LeagueView {
    func bindViewModel() {
        let input = LeaguePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            search: searchPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
