
import SwiftUI
import Combine

struct LeagueDetailView: View {
    
    @State private var showMenu = false
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let exitLeaguePublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: LeagueDetailViewModel
    let presenter: LeagueDetailPresenter
    
    init(
        presenter: LeagueDetailPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            Color.blackColor.edgesIgnoringSafeArea(.all)
            
            VStack {
                
                HStack {
                    Text("¡Ranking!")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 30)
                    
                    Spacer()
                    
                    Button(action: {
                        showMenu.toggle()
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.white)
                            .padding()
                    }
                    .confirmationDialog("Menú", isPresented: $showMenu) {
                        Button("Salir de la liga", role: .destructive) {
                            exitLeaguePublisher.send()
                        }
                    }
                }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.rankingList, id: \.id) { user in
                            RankingRow(user: user)
                        }
                    }
                }
            }
            
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
    
}

private extension LeagueDetailView {
    func bindViewModel() {
        let input = LeagueDetailPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            exit: exitLeaguePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
