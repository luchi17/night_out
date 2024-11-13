import SwiftUI
import Combine

struct SplashView: View, Hashable {

    private let presenter: SplashPresenter
    @ObservedObject private var viewModel: SplashViewModel
    
    public let id = UUID()
    
    static func == (lhs: SplashView, rhs: SplashView) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Combina el id para el hash
    }
    
    init(presenter: SplashPresenter) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    private let onAppear = PassthroughSubject<Void, Never>()
    private let goToTabView = PassthroughSubject<Void, Never>()
    private let goToLogin = PassthroughSubject<Void, Never>()
    
    var body: some View {
        VStack {
//            Button(action: {
//                goToTabView.send()
//            }) {
//                Text("TabView")
//            }
//            
//            Button(action: {
//                goToLogin.send()
//            }) {
//                Text("Login")
//            }
            Spacer()
            Text("Image pending...")
            Spacer()
        }
        .navigationTitle("Splash")
        .onAppear {
            onAppear.send()
        }
    }
}

// MARK: - Private methods
private extension SplashView {
    func bindViewModel() {
        let input = SplashPresenterImpl.Input(
            viewIsLoaded: onAppear.first().eraseToAnyPublisher(),
            login: goToLogin.first().eraseToAnyPublisher(),
            tabview: goToTabView.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
