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
    
    private let goToTabView = PassthroughSubject<Void, Never>()
    private let goToLogin = PassthroughSubject<Void, Never>()
    
    var body: some View {
        VStack {
            Button(action: {
                goToTabView.send()
            }) {
                Text("TabView")
                    .font(.headline)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                goToLogin.send()
            }) {
                Text("Login")
                    .font(.headline)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .navigationTitle("Splash")
    }
}

// MARK: - Private methods
private extension SplashView {
    func bindViewModel() {
        let input = SplashPresenterImpl.Input(
            login: goToLogin.first().eraseToAnyPublisher(),
            tabview: goToTabView.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

#warning("TODO launch view chatgpt")
struct LaunchScreen: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        guard let view = Bundle.main.loadNibNamed("LaunchScreen", owner: nil)?.first as? UIView else {
            return UIView()
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

