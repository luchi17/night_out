import SwiftUI
import Combine
import AVKit

struct SplashView: View {
    
    @StateObject private var viewModel = VideoPlayerViewModel()
    
    @State private var showMessage = ""
    
    private let presenter: SplashPresenter
    
    @ObservedObject private var splashModel: SplashViewModel
    
    private let newScreenPublisher = PassthroughSubject<Void, Never>()
    
    public let id = UUID()
    
    static func == (lhs: SplashView, rhs: SplashView) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(presenter: SplashPresenter) {
        self.presenter = presenter
        splashModel = presenter.viewModel
        bindViewModel()
    }
    
    var url: URL? = {
        guard let url = Bundle.main.url(forResource: "animacion_copa_fondo_azul", withExtension: "mp4") else {
            return nil
        }
        return url
    }()
    
    var body: some View {
        
        VStack {
            ZStack {
                
                Color.darkBlueColor
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    if AppState.shared.shouldShowSplashVideo {
                        VideoPlayer(player: viewModel.player)
                            .allowsHitTesting(false) // Deshabilita la interacción
                            .frame(width: 300, height: 300, alignment: .center)
                            .padding(.horizontal)
                            .overlay {
                                Group {
                                    if viewModel.isReady {
                                        Rectangle().fill(Color.clear)
                                    } else {
                                        
                                        ZStack {
                                            Color.darkBlueColor
                                                .ignoresSafeArea()
                                            
                                            Image("logo_amarillo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 150, height: 150)
                                        }
                                        
                                    }
                                }
                            }
                    } else {
                        Image("logo_amarillo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                    }
                   
                    Spacer()
                }
                
            }
            
        }
        .onAppear {
            if AppState.shared.shouldShowSplashVideo {
                viewModel.configurePlayer(with: url!)
            } else {
                newScreenPublisher.send()
            }
        }
        .onDisappear {
            viewModel.removeObservers()
        }
        .onChange(of: viewModel.isFinished) {
            if viewModel.isFinished {
                newScreenPublisher.send()
            }
        }
    }
    
    func bindViewModel() {
        let input = SplashPresenterImpl.Input(
            viewIsLoaded: newScreenPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

class VideoPlayerViewModel: ObservableObject {
    var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerObserver: AnyCancellable?
    private var readyCheckCancellable: AnyCancellable?
    
    @Published var isReady: Bool = false
    @Published var isFinished: Bool = false
    
    func configurePlayer(with url: URL) {
        // Crea el AVPlayerItem
        self.playerItem = AVPlayerItem(url: url)
        
        // Crea el AVPlayer y asigna el item
        self.player = AVPlayer(playerItem: playerItem)
        
        // Observa cuando el video está listo
        playerObserver = playerItem?.publisher(for: \.status)
            .sink { [weak self] status in
                if status == .readyToPlay {

                    self?.player?.play()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        self?.isReady = true
                    }
                    
                }
            }
        
        
        // Iniciar el temporizador para verificar el estado después de 2 segundos
        readyCheckCancellable = Just(())
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                if self?.playerItem?.status != .readyToPlay {
                    print("Error: El video no está listo para reproducirse después de 2 segundos.")
                    self?.isFinished = true
                }
            }
        
        // Notificación cuando el video se ha terminado
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    @objc func didFinishPlaying() {
        self.isFinished = true
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    // Método para remover observadores
    func removeObservers() {
        // Eliminar observador de la notificación
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        // Cancelar los publishers de Combine
        playerObserver?.cancel()
    }
}
