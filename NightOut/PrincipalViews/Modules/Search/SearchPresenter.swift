import SwiftUI
import Combine
import Firebase

final class SearchViewModel: ObservableObject {
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    @Published var searchText: String = ""
    @Published var searchResults: [ProfileModel] = []
    
    @Published var _results: [ProfileModel] = []
}

protocol SearchPresenter {
    var viewModel: SearchViewModel { get }
    func transform(input: SearchPresenterImpl.ViewInputs)
}

final class SearchPresenterImpl: SearchPresenter {
    
    struct UseCases {
    }
    
    struct Actions {
        let goToProfile: InputClosure<ProfileModel>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let search: AnyPublisher<Void, Never>
        let goToProfile: AnyPublisher<ProfileModel, Never>
    }
    
    var viewModel: SearchViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private var usersQuery: DatabaseQuery?
    private var companyUsersQuery: DatabaseQuery?
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = SearchViewModel()
    }
    
    func transform(input: SearchPresenterImpl.ViewInputs) {
        viewModel.$searchText
                    .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
                    .removeDuplicates()
                    .withUnretained(self)
                    .sink { presenter, query in
                        presenter.searchUsers(query: query.lowercased())
                    }
                    .store(in: &cancellables)
        
        input
            .goToProfile
            .withUnretained(self)
            .sink { presenter, model in
                presenter.actions.goToProfile(model)
            }
            .store(in: &cancellables)
        
    }
    
    private func searchUsers(query: String) {
        
        guard !query.isEmpty else {
            viewModel.searchResults.removeAll()
            return
        }
        
        viewModel.searchResults.removeAll()
        
        // Cancelar escuchadores anteriores
        usersQuery?.removeAllObservers()
        companyUsersQuery?.removeAllObservers()
        
        let group = DispatchGroup()
        // Búsqueda en la referencia "Users"
        group.enter()
        usersQuery = FirebaseServiceImpl.shared.getUsers()
                    .queryOrdered(byChild: "username")
                    .queryStarting(atValue: query)
                    .queryEnding(atValue: query + "\u{f8ff}")
        
        usersQuery?.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            var users: [ProfileModel] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    print(childSnapshot)
                    if let userModel = try? childSnapshot.data(as: UserModel.self) {
                        
                        let profile = ProfileModel(
                            profileImageUrl: userModel.image,
                            username: userModel.username,
                            fullname: userModel.fullname,
                            profileId: userModel.uid,
                            isCompanyProfile: false
                        )
                        
                        if profile.profileId != FirebaseServiceImpl.shared.getCurrentUserUid() {
                            users.append(profile)
                        }
                        
                    } else {
                        print("error")
                    }
                }
            }
            self?.viewModel._results = users
            group.leave()
        })
        
//         Buscar en la referencia "Company_Users"
        group.enter()
        let companyUsersQuery = FirebaseServiceImpl.shared.getCompanies()
            .queryOrdered(byChild: "username")
            .queryStarting(atValue: query)
            .queryEnding(atValue: query + "\u{f8ff}")

        companyUsersQuery.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            var companyUsers: [ProfileModel] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                   
                    if let companyModel = try? childSnapshot.data(as: CompanyModel.self) {
                        let profile = ProfileModel(
                            profileImageUrl: companyModel.imageUrl,
                            username: companyModel.username,
                            fullname: companyModel.fullname,
                            profileId: companyModel.uid,
                            isCompanyProfile: true
                        )
                        
                        if profile.profileId != FirebaseServiceImpl.shared.getCurrentUserUid() {
                            companyUsers.append(profile)
                        }
                        
                    } else {
                        print("error")
                    }
                }
            }
            self?.viewModel._results.append(contentsOf: companyUsers)
            group.leave()
        })
        
        group.notify(queue: .main) {
            if self.viewModel._results != self.viewModel.searchResults { // Evitar actualizar vista
                self.viewModel.searchResults = self.viewModel._results
                self.viewModel._results = self.viewModel.searchResults // Actualizar variable auxiliar
                
            }
        }
    }
}
