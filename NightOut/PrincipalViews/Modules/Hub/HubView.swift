import SwiftUI
import AVKit
import Combine

struct HubView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let stopImageSwitcherPublisher = PassthroughSubject<Void, Never>()
    private let openUrlPublisher = PassthroughSubject<String, Never>()
    
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    let presenter: HubPresenter
    
    @State private var dragOffset = CGSize.zero
    
    init(
        presenter: HubPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            
            Color.blackColor
                .edgesIgnoringSafeArea(.all)
            
            if viewModel.selectedGame != nil {
                
                VStack {
                    
                    Spacer()
                    
                    gameView
                    
                    Spacer()
                    // Agregar gesto de deslizamiento para volver
                    if keyboardObserver.keyboardHeight == 0 {
                        Text(viewModel.selectedGame == .publicamosTuVideo ? "Desliza hacia abajo para volver" : "Desliza hacia abajo para volver a los juegos")
                            .foregroundColor(.white)
                            .padding(.bottom, 15)
                    }
                }
                .transition(.move(edge: .bottom)) // Animación de entrada desde abajo
                
            } else {
                
                VStack {
                    topView
                        .transition(.move(edge: .top)) // Animación de salida hacia arriba
                    
                    Spacer()
                    
                    AdvertisementView(
                        imageList: $viewModel.imageList,
                        currentIndex: $viewModel.currentIndex,
                        openUrl: openUrlPublisher.send
                    )
                    .frame(maxWidth: .infinity, maxHeight: 110)
                    .padding(.bottom, 5)
                }
            }
        }
        .padding(.bottom, 20)
        .background(
            Color.blackColor
            .edgesIgnoringSafeArea(.all)
        )
        .animation(.easeInOut, value: viewModel.selectedGame)
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    self.dragOffset = value.translation
                }
                .onEnded { value in
                    if self.dragOffset.height > 100 {
                        // Si el usuario desliza suficientemente hacia abajo, volver a la lista
                        self.viewModel.selectedGame = nil
                    }
                }
        )
        .onAppear {
            viewDidLoadPublisher.send()
        }
        .onDisappear {
            stopImageSwitcherPublisher.send()
        }
    }
    
    var topView: some View {
        VStack {
            Image("hub_no_bg")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .padding(.top, 20)
            
            // Scroll horizontal de botones
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    GameButton(game: .yonunca, selectedGame: $viewModel.selectedGame)
                    GameButton(game: .chupitowars, selectedGame: $viewModel.selectedGame)
                    GameButton(game: .verdadOreto, selectedGame: $viewModel.selectedGame)
                    GameButton(game: .retos, selectedGame: $viewModel.selectedGame)
                    GameButton(game: .ruleta, selectedGame: $viewModel.selectedGame)
                    GameButton(game: .publicamosTuVideo, selectedGame: $viewModel.selectedGame)
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 16)
            
            Spacer()
        }
    }
    
    var gameView: some View {
        VStack {
            if viewModel.selectedGame == .yonunca {
                YoNuncaView()
            } else if viewModel.selectedGame == .chupitowars {
                ChupitoWarsView()
            } else if viewModel.selectedGame == .verdadOreto {
                VerdadORetoView()
            } else if viewModel.selectedGame == .retos {
                RetosView()
            } else if viewModel.selectedGame == .ruleta {
                RuletaView()
            } else if viewModel.selectedGame == .publicamosTuVideo {
                ShareVideoView()
            }
        }
    }

}


struct GameButton: View {
    var game: GameType
    @Binding var selectedGame: GameType?
    
    var body: some View {
        Button(action: {
            selectedGame = game
        }) {
            Text(game.title.uppercased())
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.3)))
        }
    }
}

private extension HubView {
    func bindViewModel() {
        let input = HubPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            stopImageSwitcher: stopImageSwitcherPublisher.eraseToAnyPublisher(),
            openUrl: openUrlPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

enum GameType {
    case yonunca
    case chupitowars
    case verdadOreto
    case retos
    case ruleta
    case publicamosTuVideo
    
    var title: String {
        switch self {
        case .yonunca:
            return "Yo nunca 🔥"
        case .chupitowars:
            return "Chupito Wars 🥃"
        case .verdadOreto:
            return "Verdad o reto 🎭"
        case .retos:
            return "Retos 🏆"
        case .ruleta:
            return "Ruleta 🎯"
        case .publicamosTuVideo:
            return "Publicamos tu vídeo"
        }
    }
    
    init?(rawValue: String) {
        if rawValue == GameType.yonunca.title {
            self = .yonunca
        }
        else if rawValue == GameType.chupitowars.title {
            self = .chupitowars
        }
        else if rawValue == GameType.verdadOreto.title {
            self = .verdadOreto
        }
        else if rawValue == GameType.verdadOreto.title {
            self = .retos
        }
        else if rawValue == GameType.ruleta.title {
            self = .ruleta
        }
        else {
            self = .publicamosTuVideo
        }
    }
}
