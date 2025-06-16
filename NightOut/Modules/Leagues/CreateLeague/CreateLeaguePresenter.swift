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
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
}

protocol CreateLeaguePresenter {
    var viewModel: CreateLeagueViewModel { get }
    func transform(input: CreateLeaguePresenterImpl.ViewInputs)
}

final class CreateLeaguePresenterImpl: CreateLeaguePresenter {
    
    struct UseCases {
    }
    
    struct Actions {
        let goBack: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let createLeague: AnyPublisher<Void, Never>
        let removeFriend: AnyPublisher<CreateLeagueUser, Never>
        let searchUsers: AnyPublisher<Void, Never>
        let addFriend: AnyPublisher<CreateLeagueUser, Never>
        let onDismissToast: AnyPublisher<Void, Never>
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
            .receive(on: DispatchQueue.main)
            .withUnretained(self)
            .flatMap { presenter, query -> AnyPublisher<[CreateLeagueUser], Never> in
                guard !query.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }
                return presenter.searchUsers(query: query.lowercased())
            }
            .receive(on: DispatchQueue.main)
            .withUnretained(self)
            .sink { presenter, users in
                presenter.viewModel.searchResults = users
            }
            .store(in: &cancellables)
        
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.loadCurrentUser()
            }
            .store(in: &cancellables)
        
        input
            .createLeague
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.createLeague()
            }
            .store(in: &cancellables)
        
        input
            .removeFriend
            .withUnretained(self)
            .sink { presenter, user in
                presenter.removeFriend(user)
            }
            .store(in: &cancellables)
        
        input
            .addFriend
            .withUnretained(self)
            .sink { presenter, user in
                presenter.addFriend(user)
            }
            .store(in: &cancellables)
        
        input
            .onDismissToast
            .withUnretained(self)
            .sink { presenter, user in
                presenter.actions.goBack()
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrentUser() {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        usersRef.child(currentUserId).observeSingleEvent(of: .value) { [weak self] snapshot in
            
            if let userModel = try? snapshot.data(as: UserModel.self) {
                let model = CreateLeagueUser(
                    uid: userModel.uid,
                    username: userModel.username,
                    imageUrl: userModel.image
                )
                self?.viewModel.selectedFriends.append(model)
            }
        }
    }
    
    private func searchUsers(query: String)  -> AnyPublisher<[CreateLeagueUser], Never> {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return Just([]).eraseToAnyPublisher()
        }
        
        guard !query.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        usersQuery?.removeAllObservers()
        
        let usersQuery = FirebaseServiceImpl.shared.getUsers()
                    .queryOrdered(byChild: "username")
                    .queryStarting(atValue: query)
                    .queryEnding(atValue: query + "\u{f8ff}")
        
        return Future<[CreateLeagueUser], Never> { promise in
            usersQuery.observeSingleEvent(of: .value) { snapshot in
                let users = snapshot.children.compactMap { $0 as? DataSnapshot }
                    .compactMap { try? $0.data(as: UserModel.self) }
                    .map({ userModel in
                        return CreateLeagueUser(
                            uid: userModel.uid,
                            username: userModel.username,
                            imageUrl: userModel.image
                        )
                    })
                    .filter { user in
                        user.uid != currentUserId &&
                        !self.viewModel.selectedFriends.contains(where: { $0.uid == user.uid })
                    }
                promise(.success(users))
            }
        }.eraseToAnyPublisher()
    }
    
    private func addFriend(_ user: CreateLeagueUser) {
        if !viewModel.selectedFriends.contains(where: { $0.uid == user.uid }) {
            viewModel.selectedFriends.append(user)
        }
    }
    
    private func removeFriend(_ user: CreateLeagueUser) {
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
                    }
                }
            }
        }
    }
}
