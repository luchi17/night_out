import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseDatabase

final class LeagueViewModel: ObservableObject {
    @Published var loading: Bool = true
    @Published var toast: ToastType?
    
    @Published var leaguesList: [League] = []
    @Published var showNoLeaguesDialog = false
    @Published var showDeleteAlert = false
    
    @Published var progress: Double = 0.0
    @Published var progressColor: Color = .green
    
    @Published var remainingSeconds: Int = 0
    
    var totalSeconds: Int = 0
    
    private var timer: AnyCancellable?
    
    deinit {
        timer?.cancel()
    }
    
    init() {
        initializeMonthTiming()
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    self.updateProgress()
                    self.getProgressColor()
                } else {
                    self.handleRankingEnd()
                }
            }
    }
    
    
    private func initializeMonthTiming() {
        let calendar = Calendar.current
        let currentDate = Date()
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!.addingTimeInterval(-1)
        
        totalSeconds = Int(endOfMonth.timeIntervalSince(startOfMonth))
        remainingSeconds = max(Int(endOfMonth.timeIntervalSince(currentDate)), 0)
    }
    
    private func updateProgress() {
        if totalSeconds > 0 {
            DispatchQueue.main.async {
                self.progress = (Double(self.totalSeconds - self.remainingSeconds) / Double(self.totalSeconds)) * 100
            }
        }
    }
    
    func getProgressColor() {
        switch self.progress {
        case ..<50:
            self.progressColor = Color.green
        case 50..<80:
            self.progressColor = Color.yellow
        default:
            self.progressColor = .red
        }
    }
    private func handleRankingEnd() {
        timer?.cancel()
        DispatchQueue.main.async {
            self.progress = 100
        }
    }
}

protocol LeaguePresenter {
    var viewModel: LeagueViewModel { get }
    func transform(input: LeaguePresenterImpl.ViewInputs)
}

final class LeaguePresenterImpl: LeaguePresenter {
    
    struct UseCases {
        let followUseCase: FollowUseCase
        let userDataUseCase: UserDataUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
        //        let goToCreateLeague: VoidClosure
//        let goToLeagueDetail: InputClosure<League>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let deleteLeague: AnyPublisher<League, Never>
        let openCreateLeague: AnyPublisher<Void, Never>
        let openLeagueDetail: AnyPublisher<League, Never>
    }
    
    var viewModel: LeagueViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    let userRef = FirebaseServiceImpl.shared.getUsers()
    let leaguesRef = FirebaseServiceImpl.shared.getLeagues()
    
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = LeagueViewModel()
    }
    
    func transform(input: LeaguePresenterImpl.ViewInputs) {
        
        input
            .deleteLeague
            .withUnretained(self)
            .sink { presenter, league in
                presenter.deleteLeague(league)
            }
            .store(in: &cancellables)
        
        input
            .openCreateLeague
            .withUnretained(self)
            .sink { presenter, _ in
//                presenter.actions.goToCreateLeague()
            }
            .store(in: &cancellables)
        
        input
            .openLeagueDetail
            .withUnretained(self)
            .sink { presenter, _ in
//                presenter.actions.goToLeagueDetail()
            }
            .store(in: &cancellables)
        
        input
            .viewDidLoad
            .filter({ FirebaseServiceImpl.shared.getImUser() })
            .withUnretained(self)
            .flatMap { presenter, _ -> AnyPublisher<[String: Bool]?, Never>in
                guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just([:]).eraseToAnyPublisher()
                }
                return presenter.useCases.userDataUseCase.getUserInfo(uid: userId)
                    .map({ $0?.misLigas })
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink { presenter, misLigas in
                
                if let misLigas = misLigas, !misLigas.isEmpty {
                    let ids = Array(misLigas.keys)
                    presenter.loadLeaguesDetails(leagueIds: ids)
                } else {
                    presenter.viewModel.loading = false
                    presenter.viewModel.showNoLeaguesDialog = true
                }
                
            }
            .store(in: &cancellables)
        
#warning("TODO: leagues for company")
        //        input
        //            .viewDidLoad
        //            .filter({ !FirebaseServiceImpl.shared.getImUser() })
        //            .withUnretained(self)
        //            .flatMap { presenter, _ -> AnyPublisher<[String: Bool]?, Never>in
        //                guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
        //                    return Just([:]).eraseToAnyPublisher()
        //                }
        //                return presenter.useCases.companyDataUseCase.getCompanyInfo(uid: userId)
        //                    .map({ $0?.misLigas })
        //                    .eraseToAnyPublisher()
        //            }
        //            .withUnretained(self)
        //            .sink { presenter, misLigas in
        //
        //                if let misLigas = misLigas, !misLigas.isEmpty {
        //                    let ids = Array(misLigas.keys)
        //                    presenter.fetchLeagues(ids)
        //                } else {
        //                    presenter.viewModel.showNoLeaguesDialog = true
        //                }
        //
        //            }
        //            .store(in: &cancellables)
        //
    }
    
    
    func loadLeaguesDetails(leagueIds: [String]) {
        
        let leagueRef = FirebaseServiceImpl.shared.getLeagues()
        
        self.viewModel.leaguesList = []
        
        for leagueId in leagueIds {
            leagueRef.child(leagueId).observeSingleEvent(of: .value) {  [weak self] snapshot in
                guard snapshot.exists(), let self = self else { return }
                
                let leagueName = snapshot.childSnapshot(forPath: "name").value as? String ?? "Liga Sin Nombre"
                let drinks = snapshot.childSnapshot(forPath: "drinks").childrenCount
                
                // Evitar duplicados
                if !self.viewModel.leaguesList.contains(where: { $0.leagueId == leagueId }) {
                    DispatchQueue.main.async {
                        self.viewModel.leaguesList.append(League(
                            leagueId: leagueId,
                            name: leagueName,
                            drinks: Int(drinks),
                            imageName: "copa\(Int.random(in: 1...8))"
                        )
                        )
                    }
                }
            }
        }
        
        self.viewModel.loading = false
    }
    
    private func deleteLeague(_ league: League) {
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        userRef.child(userId).child("misLigas").child(league.leagueId).removeValue()
        leaguesRef.child(league.leagueId).removeValue()
        
        viewModel.leaguesList.removeAll { $0.id == league.id }
    }
}


struct League: Identifiable {
    let id = UUID()
    let leagueId: String
    let name: String
    let drinks: Int
    let imageName: String
}
