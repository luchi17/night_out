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
        let followUseCase: FollowUseCase
    }
    
    struct Actions {
        let goToProfile: InputClosure<ProfileModel>
        let goToPrivateProfile: InputClosure<ProfileModel>
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
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withUnretained(self)
            .flatMap { presenter, query -> AnyPublisher<[ProfileModel], Never> in
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
            .goToProfile
            .withUnretained(self)
            .flatMap({ presenter, profileModel -> AnyPublisher<(FollowModel?, ProfileModel), Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just((nil, profileModel)).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: uid)
                    .map({ ($0, profileModel) })
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .sink { presenter, data in
                
                let profileModel = data.1
                let following = data.0?.following?.keys.first(where: { $0 == profileModel.profileId }) != nil
                
                if following {
                    presenter.actions.goToProfile(profileModel)
                } else {
                    if profileModel.isPrivateProfile {
                        presenter.actions.goToPrivateProfile(profileModel)
                    } else {
                        presenter.actions.goToProfile(profileModel)
                    }
                }
            }
            .store(in: &cancellables)
        
    }
    
    var searchUsersClosure: ((String) -> AnyPublisher<[ProfileModel], Never>)?
    
    public func searchUsers(query: String) -> AnyPublisher<[ProfileModel], Never> {
        if let closure = searchUsersClosure {
            return closure(query)
        }
        
        guard !query.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }
        
        // Cancelamos observadores previos antes de hacer nuevas búsquedas
        usersQuery?.removeAllObservers()
        companyUsersQuery?.removeAllObservers()
        
        let usersQuery = Database.database().reference()
            .child("Users")
            .queryOrdered(byChild: "username")
            .queryStarting(atValue: query)
            .queryEnding(atValue: query + "\u{f8ff}")
        
        let companyUsersQuery = Database.database().reference()
            .child("Company_Users")
            .queryOrdered(byChild: "username")
            .queryStarting(atValue: query)
            .queryEnding(atValue: query + "\u{f8ff}")
        
        let usersPublisher = Future<[ProfileModel], Never> { promise in
            usersQuery.observeSingleEvent(of: .value) { snapshot in
                let users = snapshot.children.compactMap { child -> ProfileModel? in
                    guard let childSnapshot = child as? DataSnapshot,
                          let userModel = try? childSnapshot.data(as: UserModel.self) else {
                        return nil
                    }
                    
                    let profile = ProfileModel(
                        profileImageUrl: userModel.image,
                        username: userModel.username,
                        fullname: userModel.fullname,
                        profileId: userModel.uid,
                        isCompanyProfile: false,
                        isPrivateProfile: userModel.profileType == .privateProfile
                    )
                    
                    if profile.profileId != FirebaseServiceImpl.shared.getCurrentUserUid() {
                        return profile
                    }
                    
                    return nil
                }
                promise(.success(users))
            }
        }
        
        let companyUsersPublisher = Future<[ProfileModel], Never> { promise in
            
            companyUsersQuery.observeSingleEvent(of: .value) { snapshot in
                
                let companyUsers = snapshot.children.compactMap { child -> ProfileModel? in
                    guard let childSnapshot = child as? DataSnapshot,
                          let companyModel = try? childSnapshot.data(as: CompanyModel.self) else {
                        return nil
                    }
                    
                    let profile = ProfileModel(
                        profileImageUrl: companyModel.imageUrl,
                        username: companyModel.username,
                        fullname: companyModel.fullname,
                        profileId: companyModel.uid,
                        isCompanyProfile: !(companyModel.location?.isEmpty ?? true),
                        isPrivateProfile: companyModel.profileType == .privateProfile
                    )
                    
                    if profile.profileId != FirebaseServiceImpl.shared.getCurrentUserUid() {
                        return profile
                    }
                    
                    return nil
                }
                promise(.success(companyUsers))
            }
        }
        
        
        return Publishers.CombineLatest(usersPublisher, companyUsersPublisher)
            .map { users, companyUsers in
                let combinedResults = (users + companyUsers).uniqued() // Eliminar duplicados
                return combinedResults
            }
            .eraseToAnyPublisher()
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
