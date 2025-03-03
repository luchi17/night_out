import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseDatabase

final class LeagueDetailViewModel: ObservableObject {
    
    @Published var loading: Bool = true
    @Published var toast: ToastType?
    @Published var rankingList: [UserRanking] = []

}

protocol LeagueDetailPresenter {
    var viewModel: LeagueDetailViewModel { get }
    func transform(input: LeagueDetailPresenterImpl.ViewInputs)
}

final class LeagueDetailPresenterImpl: LeagueDetailPresenter {
    
    struct UseCases {
        let userDataUseCase: UserDataUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
        //        let goToCreateLeague: VoidClosure
        //        let goToLeagueDetail: InputClosure<League>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let exit: AnyPublisher<Void, Never>
    }
    
    var viewModel: LeagueDetailViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private let league: League
    
    private var cancellables = Set<AnyCancellable>()
    
    private let leaguesRef = FirebaseServiceImpl.shared.getLeagues()
    
    init(
        useCases: UseCases,
        actions: Actions,
        league: League
    ) {
        self.actions = actions
        self.useCases = useCases
        self.league = league
        
        viewModel = LeagueDetailViewModel()
    }
    
    func transform(input: LeagueDetailPresenterImpl.ViewInputs) {
    
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.loadRankingData()
            }
            .store(in: &cancellables)
        
        input
            .exit
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.exitLeague()
            }
            .store(in: &cancellables)
    }
    
    private func loadRankingData() {
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        leaguesRef.child(league.leagueId).child("drinks").observeSingleEvent(of: .value) { snapshot in
            
            var rankings: [UserRanking] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let drinksCount = childSnapshot.value as? Int {
                    
                    let userId = childSnapshot.key
                    
                    FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userId).child("username").observeSingleEvent(of: .value) { userSnapshot in
                        if let username = userSnapshot.value as? String {
                            rankings.append(UserRanking(uid: userId, username: username, drinks: drinksCount))
                        }
                        
                        if rankings.count == snapshot.childrenCount {
                            self.viewModel.rankingList = rankings.sorted(by: { $0.drinks > $1.drinks })
                        }
                    }
                }
            }
        }
    }
    
    private func exitLeague() {
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let leagueRef = leaguesRef.child(league.leagueId)
        let userRef = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userId).child("misLigas").child(league.leagueId)

        leagueRef.child("users").child(userId).removeValue { error, _ in
            guard error == nil else { return }
            
            leagueRef.child("drinks").child(userId).removeValue { error, _ in
                guard error == nil else { return }
                
                userRef.removeValue { error, _ in
                    guard error == nil else { return }
                    
                    DispatchQueue.main.async {
                        // Aquí podrías cerrar la vista, dependiendo de la navegación
                    }
                }
            }
        }
    }
    
    
}
