import SwiftUI
import Combine

struct UserProfileView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let logoutPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: UserViewModel
    let presenter: UserPresenter
    
    init(
        presenter: UserPresenter
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
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .onAppear(perform: viewDidLoadPublisher.send)
    }
}


private extension UserProfileView {
    
    func bindViewModel() {
        let input = UserPresenterImpl.Input(
            viewIsLoaded: viewDidLoadPublisher.eraseToAnyPublisher(),
            logout: logoutPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
