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
//        let notificationsUseCase: NotificationsUseCase
//        let userDataUseCase: UserDataUseCase
//        let followUseCase: FollowUseCase
    }
    
    struct Actions {
//        let goToProfile: InputClosure<ProfileModel>
//        let goToPost: InputClosure<NotificationModelForView>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let search: AnyPublisher<Void, Never>
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
                    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                    .removeDuplicates()
                    .withUnretained(self)
                    .sink { presenter, query in
                        presenter.searchUsers(query: query)
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
        
        // Búsqueda en la referencia "Users"
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
                        users.append(profile)
                        
                    } else {
                        print("error")
                    }
                }
            }
            self?.viewModel._results = users
        })
        
        // Buscar en la referencia "Company_Users"
        let companyUsersQuery = FirebaseServiceImpl.shared.getCompanies()
            .queryOrdered(byChild: "username")
            .queryStarting(atValue: query)
            .queryEnding(atValue: query + "\u{f8ff}")

        companyUsersQuery.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            var companyUsers: [ProfileModel] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    print(childSnapshot)
                    if let companyModel = try? childSnapshot.data(as: CompanyModel.self) {
                        let profile = ProfileModel(
                            profileImageUrl: companyModel.imageUrl,
                            username: companyModel.username,
                            fullname: companyModel.fullname,
                            profileId: companyModel.uid,
                            isCompanyProfile: true
                        )
                        companyUsers.append(profile)
                    } else {
                        print("error")
                    }
                }
            }
            self?.viewModel._results.append(contentsOf: companyUsers)
        })
        
        if self.viewModel._results != self.viewModel.searchResults { // Evitar actualizar vista
            self.viewModel.searchResults = self.viewModel._results
            self.viewModel._results = self.viewModel.searchResults // Actualizar variable auxiliar
            
        }
         
    }
}
