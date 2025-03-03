
import SwiftUI
import Combine

struct LeagueView: View {
    
    @State private var showHelp: Bool = false
    @State private var leagueToDelete: League?
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let deleteLeaguePublisher = PassthroughSubject<League, Never>()
    private let openCreateLeaguePublisher = PassthroughSubject<Void, Never>()
    
    
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
                        Text("Crea una liga")
                            .foregroundColor(.white)
                            .frame(width: 150, height: 50)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    Spacer()
                    Button(action: {
                        showHelp = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                }
                
                Image(systemName: "clock.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                progressView
                
                Text("Ligas en las que participas")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
//                ScrollView {
//                    VStack {
//                        ForEach(viewModel.leaguesList, id: \.self) { league in
//                            Text(league)
//                                .foregroundColor(.white)
//                                .padding()
//                                .frame(maxWidth: .infinity)
//                                .background(Color.gray.opacity(0.3))
//                                .cornerRadius(10)
//                                .padding(.horizontal)
//                        }
//                    }
//                }
            }
            .padding()
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
        .alert("Eliminar Liga", isPresented: $viewModel.showDeleteAlert, presenting: leagueToDelete) { league in
            Button("Sí", role: .destructive) {
                deleteLeaguePublisher.send(league)
            }
            Button("Cancelar", role: .cancel) { }
        } message: { _ in
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
                    .font(.largeTitle)
                    .foregroundColor(.white)
            } else {
                Text(formattedTime(viewModel.remainingSeconds))
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            
            ProgressView(value: viewModel.progress, total: 100)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(viewModel.progressColor)
                .frame(height: 10)
                .padding(.horizontal)
        }
    }
    
}

private extension LeagueView {
    func bindViewModel() {
        let input = LeaguePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            deleteLeague: deleteLeaguePublisher.eraseToAnyPublisher(),
            openCreateLeague: openCreateLeaguePublisher.eraseToAnyPublisher()
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
                    .padding(.top, 8)
                
                Spacer()
                
                Text("Parece que no tienes ninguna liga creada.\n¿Quieres crear una nueva?")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top, 8)
                
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
            
        }
        .padding()
    }
}
