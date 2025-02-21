import SwiftUI
import AVKit
import Combine

struct HubView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let gameTappedPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: HubViewModel
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
            Color.black.ignoresSafeArea()
            
            if let game = viewModel.selectedGame {
                
                VStack {
                    
                    Spacer()
                    
                    gameView
                    
                    Spacer()
                    // Agregar gesto de deslizamiento para volver
                    Text("Desliza hacia abajo para volver a los juegos")
                        .foregroundColor(.white)
                        .padding(.bottom, 35)
                }
                .transition(.move(edge: .bottom)) // Animación de entrada desde abajo
                
            } else {
                
                topView
                    .transition(.move(edge: .top)) // Animación de salida hacia arriba
                
            }
        }
        .animation(.easeInOut, value: viewModel.selectedGame)
        .gesture(
            DragGesture()
                .onChanged { value in
                    self.dragOffset = value.translation
                }
                .onEnded { value in
                    print(self.dragOffset.height)
                    if self.dragOffset.height > 100 {
                        // Si el usuario desliza suficientemente hacia abajo, volver a la lista
                        self.viewModel.selectedGame = nil
                    }
                }
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
                YoNuncaView()
            } else if viewModel.selectedGame == .verdadOreto {
                VerdadORetoView()
            } else if viewModel.selectedGame == .ruleta {
                RuletaView()
            } else if viewModel.selectedGame == .publicamosTuVideo {
                YoNuncaView()
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

// Vista de placeholder para el VideoView / ImageView
struct VideoPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
            Image("video_placeholder")
                .resizable()
                .scaledToFill()
        }
        .cornerRadius(10)
    }
}

private extension HubView {
    func bindViewModel() {
        let input = HubPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

enum GameType {
    case yonunca
    case chupitowars
    case verdadOreto
    case ruleta
    case publicamosTuVideo
    case none
    
    var title: String {
        switch self {
        case .yonunca:
            return "Yo nunca 🔥"
        case .chupitowars:
            return "Chupito Wars 🥃"
        case .verdadOreto:
            return "Verdad o reto 🎭"
        case .ruleta:
            return "Ruleta 🎯"
        case .publicamosTuVideo:
            return "Publicamos tu vídeo"
        case .none:
            return ""
        }
    }
    
    init?(rawValue: String?) {
        guard let rawValue = rawValue else {
            self = .none
            return
        }
        if rawValue == GameType.yonunca.title {
            self = .yonunca
        }
        else if rawValue == GameType.chupitowars.title {
            self = .chupitowars
        }
        else if rawValue == GameType.verdadOreto.title {
            self = .verdadOreto
        }
        else if rawValue == GameType.ruleta.title {
            self = .ruleta
        }
        else if rawValue == GameType.publicamosTuVideo.title {
            self = .publicamosTuVideo
        }
        else {
            self = .none
        }
        
    }
}
