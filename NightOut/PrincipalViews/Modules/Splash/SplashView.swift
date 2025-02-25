import SwiftUI
import Combine
import AVKit

struct SplashView: View, Hashable {
    
    private let presenter: SplashPresenter
    @ObservedObject private var viewModel: SplashViewModel
    
    private let newScreenPublisher = PassthroughSubject<Void, Never>()
    
    private let notificationName = Notification.Name.AVPlayerItemDidPlayToEndTime
    
    public let id = UUID()
    
    static func == (lhs: SplashView, rhs: SplashView) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Combina el id para el hash
    }
    
    var url: URL? = {
        guard let url = Bundle.main.url(forResource: "animacion_copa_fondo_azul", withExtension: "mp4") else {
            return nil
        }
        return url
    }()
    
    var player: AVPlayer
    
    init(presenter: SplashPresenter) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        player = AVPlayer(url: url!)
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            
            Color.darkBlueColor
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VideoPlayer(player: player)
                    .overlay(Rectangle().fill(Color.clear))
                    .allowsHitTesting(false) // Deshabilita la interacción
                    .frame(width: 300, height: 300, alignment: .center)
                    .padding(.horizontal)
                
                Spacer()
            }
            
        }
        .onAppear {
            player.play()
            // Observa cuando el video termine
            NotificationCenter.default.addObserver(
                forName: notificationName,
                object: player.currentItem,
                queue: .main
            ) { _ in
                newScreenPublisher.send()
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: notificationName, object: player.currentItem)
        }
    }
    
    func bindViewModel() {
        let input = SplashPresenterImpl.Input(
            viewIsLoaded: newScreenPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
