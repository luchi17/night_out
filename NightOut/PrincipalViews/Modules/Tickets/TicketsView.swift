import SwiftUI
import Combine

struct TicketsView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let logoutPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: TicketsViewModel
    let presenter: TicketsPresenter
    
    init(
        presenter: TicketsPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            Text("User View")
            Spacer()
            Button(action: {
                logoutPublisher.send()
            }) {
                Text("Logout")
                    .font(.headline)
                    .padding()
                    .background(Color.blackColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .onAppear(perform: viewDidLoadPublisher.send)
    }
}


private extension TicketsView {
    
    func bindViewModel() {
        let input = TicketsPresenterImpl.Input(
            viewIsLoaded: viewDidLoadPublisher.eraseToAnyPublisher(),
            logout: logoutPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
