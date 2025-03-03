
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
                List(viewModel.rankingList) { userRanking in
                    RankingRow(
                        userRanking: userRanking,
                        isCurrentUser: userRanking.uid == FirebaseServiceImpl.shared.getCurrentUserUid()
                    )
                }
                .onAppear {
                    viewDidLoadPublisher.send()
                }
                
                Button(action: {
                    showMenu.toggle()
                }) {
                    Image(systemName: "ellipsis.circle")
                        .padding()
                }
                .confirmationDialog("Menú", isPresented: $showMenu) {
                    Button("Salir de la liga", role: .destructive) {
                        exitLeaguePublisher.send()
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
        .navigationBarBackButtonHidden()
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
