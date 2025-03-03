
import SwiftUI
import Combine

struct LeagueView: View {
    
    @State private var showHelp: Bool = false
    @State private var leagueToDelete: League?
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let deleteLeaguePublisher = PassthroughSubject<League, Never>()
    private let openCreateLeaguePublisher = PassthroughSubject<Void, Never>()
    private let openLeaguePublisher = PassthroughSubject<League, Never>()
    
    
    @ObservedObject var viewModel: LeagueViewModel
    let presenter: LeaguePresenter
    
    init(
        presenter: LeaguePresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                HStack {
                    Button(action: {
                        openCreateLeaguePublisher.send()
                    }) {
                        Text("Crea una liga".uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.grayColor)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                    Spacer()
                    Button(action: {
                        showHelp = true
                    }) {
                        Image("help_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                    }
                }
                
                Image("icon_clock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                progressView
                
                Text("Ligas en las que participas")
                    .font(.system(size: 20, weight: .bold))
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    VStack {
                        ForEach(viewModel.leaguesList, id: \.id) { league in
                            LeagueRow(
                                league: league,
                                onSelect: {
                                    openLeaguePublisher.send(league)
                                },
                                onLongPress: {
                                    leagueToDelete = league
                                    viewModel.showDeleteAlert.toggle()
                                })
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 35)
        }
        .background(
            Color.black
                .edgesIgnoringSafeArea(.top)
        )
        .overlay(content: {
            if viewModel.showNoLeaguesDialog {
                CreateLeagueDialog(
                    createLeague: openCreateLeaguePublisher.send,
                    showSheet: $viewModel.showNoLeaguesDialog
                )
                .frame(height: 120)
            }
        })
        .alert("Eliminar Liga", isPresented: $viewModel.showDeleteAlert) {
            Button("Sí", role: .destructive) {
                if let leagueToDelete = leagueToDelete {
                    deleteLeaguePublisher.send(leagueToDelete)
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("¿Estás seguro de eliminar esta liga?")
        }
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
    
    
    var progressView: some View {
        
        VStack {
            if viewModel.progress == 100 {
                Text("¡Ranking Terminado!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text(formattedTime(viewModel.remainingSeconds))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }
            
            ProgressView(value: viewModel.progress, total: 100)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(viewModel.progressColor)
                .frame(height: 20)
        }
    }
    
}

private extension LeagueView {
    func bindViewModel() {
        let input = LeaguePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            deleteLeague: deleteLeaguePublisher.eraseToAnyPublisher(),
            openCreateLeague: openCreateLeaguePublisher.eraseToAnyPublisher(),
            openLeagueDetail: openLeaguePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    private func formattedTime(_ seconds: Int) -> String {
        let days = seconds / (24 * 60 * 60)
        let hours = (seconds % (24 * 60 * 60)) / (60 * 60)
        let minutes = (seconds % (60 * 60)) / 60
        let sec = seconds % 60
        return String(format: "%02dd:%02dh:%02dm:%02ds", days, hours, minutes, sec)
    }
}


struct CreateLeagueDialog: View {
    var createLeague: VoidClosure
    @Binding var showSheet: Bool
    
    var body: some View {
        
        ZStack(alignment: .topLeading) {
            
            VStack {
                
                Text("No tienes ligas")
                    .foregroundStyle(.white)
                    .font(.system(size: 18, weight: .bold))
                    .frame(alignment: .center)
                    .padding(.top, 8)
                
                
                Spacer()
                
                Text("Parece que no tienes ninguna liga creada.\n¿Quieres crear una nueva?")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .medium))
                    .frame(alignment: .center)
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showSheet = false
                        createLeague()
                    }) {
                        Text("Si".uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(Color.grayColor)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                    .padding(.top, 10)
                    Button(action: {
                        showSheet = false
                    }) {
                        Text("No".uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(Color.grayColor)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                    .padding(.top, 15)
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            
            Image("chupito_dialog_nb")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(.leading, 12)
                .padding(.top, 12)
            
        }
        .padding()
    }
}

struct LeagueRow: View {
    let league: League
    let onSelect: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Text(league.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Image(league.imageName)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                Spacer()
            }
            
            Text("Miembros: \(league.drinks)")
                .font(.subheadline)
                .foregroundColor(.yellow)
        }
        .onTapGesture { onSelect() }
        .onLongPressGesture { onLongPress() }
    }
}
