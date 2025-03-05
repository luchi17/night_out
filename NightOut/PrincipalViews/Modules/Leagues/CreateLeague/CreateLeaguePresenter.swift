import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseDatabase

final class CreateLeagueViewModel: ObservableObject {
    
    @Published var leagueName: String = ""
    @Published var searchText: String = ""
    @Published var selectedFriends: [CreateLeagueUser] = []
    @Published var searchResults: [CreateLeagueUser] = []
    @Published var isSearching: Bool = false
    
    @Published var loading: Bool = true
    @Published var toast: ToastType?
    
    private var _results: [CreateLeagueUser] = []
    
}

protocol CreateLeaguePresenter {
    var viewModel: CreateLeagueViewModel { get }
    func transform(input: CreateLeaguePresenterImpl.ViewInputs)
}

final class CreateLeaguePresenterImpl: CreateLeaguePresenter {
    
    struct UseCases {
        let userDataUseCase: UserDataUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
        let goBack: VoidClosure
        //        let goToLeagueDetail: InputClosure<League>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let createLeague: AnyPublisher<Void, Never>
        let removeFriend: AnyPublisher<User, Never>
        let searchUsers: AnyPublisher<Void, Never>
        let addFriend: AnyPublisher<User, Never>
    }
    
    var viewModel: CreateLeagueViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    
    private var cancellables = Set<AnyCancellable>()
    
    private let usersRef = FirebaseServiceImpl.shared.getUsers()
    private var usersQuery: DatabaseQuery?
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = CreateLeagueViewModel()
    }
    
    func transform(input: CreateLeaguePresenterImpl.ViewInputs) {
        
        viewModel.$searchText
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withUnretained(self)
            .sink { presenter, query in
                presenter.searchUsers(query: query.lowercased())
            }
            .store(in: &cancellables)
        
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.loadCurrentUser()
            }
            .store(in: &cancellables)
        
    }
    
    
    private func loadCurrentUser() {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        usersRef.child(currentUserId).observeSingleEvent(of: .value) { [weak self] snapshot in
            if let user = try? snapshot.data(as: CreateLeagueUser.self) {
                self?.viewModel.selectedFriends.append(user)
            }
        }
    }
    
    private func searchUsers(query: String) {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        guard !query.isEmpty else {
            viewModel.searchResults.removeAll()
            return
        }
        
        viewModel.searchResults.removeAll()
        
        usersQuery?.removeAllObservers()
        
        let group = DispatchGroup()
        
        group.enter()
        
        usersQuery = FirebaseServiceImpl.shared.getUsers()
                    .queryOrdered(byChild: "username")
                    .queryStarting(atValue: query)
                    .queryEnding(atValue: query + "\u{f8ff}")
        
        usersQuery?
            .observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self else { return }
                self.viewModel.searchResults = snapshot.children.compactMap { $0 as? DataSnapshot }
                    .compactMap { try? $0.data(as: User.self) }
                    .filter { user in
                        user.uid != currentUserId &&
                        !self.viewModel.selectedFriends.contains(where: { $0.uid == user.uid })
                    }
                group.leave()
            }
        
        group.notify(queue: .main) {
            if self.viewModel._results != self.viewModel.searchResults { // Evitar actualizar vista
                self.viewModel.searchResults = self.viewModel._results
                self.viewModel._results = self.viewModel.searchResults // Actualizar variable auxiliar
                
            }
        }
    }
    
    private func addFriend(_ user: User) {
        if !viewModel.selectedFriends.contains(where: { $0.uid == user.uid }) {
            viewModel.selectedFriends.append(user)
        }
    }
    
    private func removeFriend(_ user: User) {
        viewModel.selectedFriends.removeAll { $0.uid == user.uid }
    }
    
    private func createLeague() {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid(),
              viewModel.selectedFriends.contains(where: { $0.uid == currentUserId }) else {
            self.viewModel.toast = .custom(.init(title: "", description: "Debes incluirte en la liga.", image: nil))
            return
        }
        
        if viewModel.leagueName.isEmpty {
            self.viewModel.toast = .custom(.init(title: "", description: "Por favor, ingresa un nombre para la liga.", image: nil))
            return
        }
        
        let leaguesRef = FirebaseServiceImpl.shared.getLeagues().childByAutoId()
        
        guard let leagueId = leaguesRef.key else {
            self.viewModel.toast = .custom(.init(title: "", description: "Error al generar ID de la liga.", image: nil))
            return
        }
        
        let selectedUserUIDs = viewModel.selectedFriends.map { $0.uid }
        
        let leagueData: [String: Any] = [
            "name": viewModel.leagueName,
            "users": selectedUserUIDs
        ]
        
        leaguesRef.setValue(leagueData) { [weak self] error, _ in
            guard let self = self else { return }
            if let error = error {
                self.viewModel.toast = .custom(.init(title: "", description: "Error al crear la liga: \(error.localizedDescription)", image: nil))
                return
            }
            
            let drinksData = Dictionary(uniqueKeysWithValues: selectedUserUIDs.map { ($0, 0) })
            
            leaguesRef.child("drinks").setValue(drinksData) { error, _ in
                if let error = error {
                    self.viewModel.toast = .custom(.init(title: "", description: "Error al inicializar drinks para la liga: \(error.localizedDescription)", image: nil))
                    return
                }
                
                var updates: [String: Any] = [:]
                
                for uid in selectedUserUIDs {
                    updates["Users/\(uid)/misLigas/\(leagueId)"] = true
                }
                
                Database.database().reference().updateChildValues(updates) { error, _ in
                    if let error = error {
                        self.viewModel.toast = .custom(.init(title: "", description: "Error al actualizar mis ligas: \(error.localizedDescription)", image: nil))
                    } else {
                        self.viewModel.toast = .success(.init(title: "", description: "Liga creada exitosamente!", image: nil))
                        self.actions.goBack()
                    }
                }
            }
        }
    }
}
