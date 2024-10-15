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
        .onAppear {
            onAppear.send()
        }
    }
    
//    var body: some View {
//            ZStack {
//                if viewModel.isSplashActive {
//                    // La vista del splash screen
//                    VStack {
//                        Text("Splash Screen")
//                            .font(.largeTitle)
//                            .bold()
//                        ProgressView() // Indicador de carga, opcional
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .background(Color.blue)
//                } else {
//                    // La siguiente vista que aparece cuando se oculta el splash
//                    MainView()
//                }
//            }
//            .animation(.easeInOut, value: viewModel.isSplashActive) // Para animar la transición
//        }
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

