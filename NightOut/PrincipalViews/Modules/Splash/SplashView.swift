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
    
    var body: some View {
        VStack {
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
            viewIsLoaded: onAppear.first().eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
