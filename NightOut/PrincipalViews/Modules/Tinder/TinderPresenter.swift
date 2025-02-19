import SwiftUI
import Combine
import Firebase


struct TinderUser: Identifiable {
    let id = UUID()
    let uid: String
    let name: String
    let image: String?
    let gender: String?
}


final class TinderViewModel: ObservableObject {
    
    @Published var loadingUsers: Bool = false
    @Published var loadingAssistance: Bool = false
    
    @Published var toast: ToastType?
    
    @Published var users: [TinderUser] = []
    
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var alertTitle: String = ""
    @Published var alertButtonText: String = ""
    @Published var shouldOpenConfig: Bool = false
    
    @Published var currentIndex: Int = 0
    
}

protocol TinderPresenter {
    var viewModel: TinderViewModel { get }
    func transform(input: TinderPresenterImpl.ViewInputs)
}

final class TinderPresenterImpl: TinderPresenter {
    
    struct UseCases {
        let userDataUseCase: UserDataUseCase
        let clubUseCase: ClubUseCase
    }
    
    struct Actions {
        let goBack: VoidClosure
        let openProfile: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let userLiked: AnyPublisher<String, Never>
        let goBack: AnyPublisher<Void, Never>
        let initTinder: AnyPublisher<Void, Never>
    }
    
    var viewModel: TinderViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    
    private let loadUsersSubject = PassthroughSubject<Void, Never>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        
        viewModel = TinderViewModel()
    }
    
    func transform(input: TinderPresenterImpl.ViewInputs) {
        
        input
            .userLiked
            .withUnretained(self)
            .sink { presenter, userLikedUid in
                presenter.setUserLiked(likedUserId: userLikedUid)
                presenter.viewModel.users = presenter.viewModel.users.filter({ $0.uid != userLikedUid })
                //TODO: Move to next user: CHECK
                presenter.viewModel.currentIndex += 1
            }
            .store(in: &cancellables)
        
        loadUsersSubject
            .withUnretained(self)
            .flatMap { presenter, _ in
                presenter.loadCurrentUserSex()
            }
            .withUnretained(self)
            .flatMap { presenter, currentSex -> AnyPublisher<([TinderUser], String?), Never> in
                if let currentSex = currentSex {
                    return presenter.loadUsers(currentUserSex: currentSex)
                        .map({ ($0, currentSex) })
                        .eraseToAnyPublisher()
                } else {
                    print("Failed to load current user sex")
                    return Just(([], currentSex)).eraseToAnyPublisher()
                }
            }
            .withUnretained(self)
            .sink { presenter, data in
                presenter.viewModel.loadingUsers = false
                
                print("DATA")
                print(data.0)
                print(data.1)

                if data.1 != nil {
                    presenter.viewModel.users = data.0
                } else {
                    presenter.viewModel.showAlert = true
                    presenter.viewModel.shouldOpenConfig = true
                    presenter.viewModel.alertTitle = "Género"
                    presenter.viewModel.alertMessage = "Debes seleccionar el género en los ajustes de tu perfil."
                    presenter.viewModel.alertButtonText = "Abrir configuración"
                }
            }
            .store(in: &cancellables)
        
        input
            .goBack
            .withUnretained(self)
            .sink { presenter, _ in
                if presenter.viewModel.shouldOpenConfig {
                    presenter.actions.openProfile()
                } else {
                    presenter.actions.goBack()
                }
            }
            .store(in: &cancellables)
        
        input
            .initTinder
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.getClubIdForCurrentUser()
            }, loadingClosure: { [weak self] loading in
                self?.viewModel.loadingAssistance = loading
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error != nil {
                    self.viewModel.toast = .custom(.init(title: "Error", description: error?.localizedDescription, image: nil))
                }
            })
            .withUnretained(self)
            .sink { presenter, clubId in
                
                if clubId != nil {
                    
#warning("TODO: REMOVE, just to try")
                    presenter.viewModel.loadingUsers = true
                    presenter.loadUsersSubject.send()
                    
                    //                    // Validar horario permitido (21:00 - 00:00)
                    //                    let calendar = Calendar.current
                    //                    let currentHour = calendar.component(.hour, from: Date())
                    //
                    //                    if currentHour >= 21 || currentHour < 2 {
                    //                        // Navegar a TinderListView dentro del horario permitido
                    //                        presenter.viewModel.loadingUsers = true
                    //                    } else {
                    //                        // Mostrar diálogo indicando fuera de horario
                    //                        presenter.viewModel.showAlert = true
                    //                    presenter.viewModel.shouldOpenConfig = false
                    //                        presenter.viewModel.alertTitle = "Fuera de horario"
                    //                        presenter.viewModel.alertMessage = "Solo puedes acceder a las fotos de los demás entre las 21:00 y las 00:00."
                    //                    presenter.viewModel.alertButtonText = "ACEPTAR"
                    //                    }
                } else {
                    presenter.viewModel.showAlert = true
                    presenter.viewModel.shouldOpenConfig = false
                    presenter.viewModel.alertTitle = "Confirmar asistencia"
                    presenter.viewModel.alertMessage = "Debes confirmar tu asistencia a un club para continuar."
                    presenter.viewModel.alertButtonText = "ACEPTAR"
                }
            }
            .store(in: &cancellables)
        
    }
    
    private func getClubIdForCurrentUser() -> AnyPublisher<String?, Never> {
        return Future { promise in
            guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                promise(.success(nil))
                return
            }
            
            let clubsRef = FirebaseServiceImpl.shared.getClub()
            
            clubsRef.observeSingleEvent(of: .value) { snapshot in
                for clubSnapshot in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                    let assistanceRef = clubSnapshot.childSnapshot(forPath: "Assistance").childSnapshot(forPath: uid)
                    if assistanceRef.exists() {
                        let clubId = clubSnapshot.key
                        promise(.success(clubId))
                        return
                    }
                }
                promise(.success(nil)) // No se encontró el club
            } withCancel: { error in
                print("Error fetching club: \(error.localizedDescription)")
                promise(.success(nil))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func setUserLiked(likedUserId: String) {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return
        }
        FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: currentUserId).child("Liked").child(likedUserId).setValue(true) { error, _ in
            if let error = error {
                print("Error al dar like al usuario \(likedUserId): \(error.localizedDescription)")
            } else {
                print("Usuario \(likedUserId) liked exitosamente")
            }
        }
    }
    
    private func loadCurrentUserSex() -> AnyPublisher<String?, Never> {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return self.getClubIdForCurrentUser()
            .withUnretained(self)
            .flatMap { presenter, clubId -> AnyPublisher<String?, Never> in
                guard let clubId = clubId else {
                    print("Club ID no encontrado")
                    return Just(nil).eraseToAnyPublisher()
                }
                return presenter.useCases.clubUseCase.getAssistance(profileId: clubId)
                    .map { assistance in
                        let myGender = assistance[currentUserId]?.gender
                        return myGender
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func loadUsers(currentUserSex: String) -> AnyPublisher<[TinderUser], Never> {
        
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return Just([]).eraseToAnyPublisher()
        }
        
        return getClubIdForCurrentUser()
            .withUnretained(self)
            .flatMap({ presenter, clubId -> AnyPublisher<(String?, [String]), Never> in
                presenter.useCases.userDataUseCase.getUserInfo(uid: currentUserId)
                    .map { userModel in
                        if let liked = userModel?.Liked?.keys {
                            return (clubId, Array(liked))
                        } else {
                            return (clubId, [])
                        }
                    }
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .flatMap { presenter, data -> AnyPublisher<([ClubAssistance], String), Never> in
                guard let clubId = data.0 else {
                    print("Club ID no encontrado")
                    return Just(([], "")).eraseToAnyPublisher()
                }
                return presenter.useCases.clubUseCase.getAssistance(profileId: clubId)
                    .map { users in
                        
                        let usersToLoad =
                        users.filter { user in
                            return user.key != currentUserId &&
                            !data.1.contains(where: { $0 != user.key }) //Filter liked users
                        }.values
                        
                        return (Array(usersToLoad), currentUserSex)
                    }
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .flatMap { presenter, data -> AnyPublisher<[TinderUser], Never> in

                presenter.loadUsersDetails(
                    users: data.0,
                    currentUserSex: data.1
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func loadUsersDetails(users: [ClubAssistance], currentUserSex: String) -> AnyPublisher<[TinderUser], Never> {
        
        print("loadUserDetails")
        print(users)
        let publishers: [AnyPublisher<TinderUser, Never>] = users.map { user in
            
            return useCases.userDataUseCase.getUserInfo(uid: user.uid)
                .compactMap({ userModel -> TinderUser? in
                    
                    guard let userModel = userModel else {
                        return nil
                    }
                    if userModel.gender == nil ||
                        userModel.gender == currentUserSex ||
                        userModel.social?.lowercased() == "no participando" {
                        return nil
                    } else {
                        return TinderUser(
                            uid: userModel.uid,
                            name: userModel.username,
                            image: userModel.image,
                            gender: user.gender
                        )
                    }
                })
                .compactMap({ $0 })
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
}
