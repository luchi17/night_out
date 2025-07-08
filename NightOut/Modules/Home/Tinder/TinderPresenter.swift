import SwiftUI
import Combine
import Firebase


struct TinderUser: Identifiable {
    let id = UUID()
    let uid: String
    let name: String
    let image: String
    var liked: Bool = false
}


final class TinderViewModel: ObservableObject {
    
    @Published var loadingUsers: Bool = false
    
    @Published var toast: ToastType?
    
    @Published var users: [TinderUser] = []
    
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var alertTitle: String = ""
    @Published var alertButtonText: String = ""
    @Published var shouldOpenConfig: Bool = false
    
    @Published var showNoUsersForClub: Bool = false
    @Published var showEndView: Bool = false
    
    @Published var currentIndex: Int = 0
    @Published var currentUserSex: String = ""
    
    var clubId: String = ""
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
    
    private let currentDateString: String?
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        viewModel = TinderViewModel()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 7
        dateComponents.day = 20
        
        let date = Calendar.current.date(from: dateComponents)
        let currentDate = dateFormatter.string(from: date!)
        
        
//        let currentHour = Calendar.current.component(.hour, from: Date())
//
//        // Determinamos la fecha a usar dependiendo de la hora
//        let currentDate: String = {
//            let formatter = DateFormatter()
//            formatter.dateFormat = "dd-MM-yyyy"
//            formatter.locale = Locale.current
//
//            if (0...2).contains(currentHour) {
//                // Si está entre las 00:00 y las 02:00, usamos la fecha de ayer
//                if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
//                    return formatter.string(from: yesterday)
//                }
//            }
//
//            // Si no, usamos la fecha actual
//            return formatter.string(from: Date())
//        }()

        print("Fecha seleccionada: \(currentDate)")

        self.currentDateString = currentDate
    }
    
    func checkViewToShow(users: [TinderUser]?) {
        
        viewModel.showEndView = false
        viewModel.showNoUsersForClub = false
        viewModel.loadingUsers = false
        
        if let users = users {
            
            if !users.isEmpty {
                viewModel.users = users
            } else {
                viewModel.showEndView = true
            }
        } else {
            viewModel.showNoUsersForClub = true
        }
    }
    
    func transform(input: TinderPresenterImpl.ViewInputs) {
        
        input
            .userLiked
            .withUnretained(self)
            .sink { presenter, userLikedUid in
                presenter.setUserLiked(likedUserId: userLikedUid)
                let users = presenter.viewModel.users.filter({ $0.uid != userLikedUid })
                presenter.checkViewToShow(users: users)
            }
            .store(in: &cancellables)
        
        loadUsersSubject
            .withUnretained(self)
            .flatMap { presenter, currentSex -> AnyPublisher<[TinderUser]?, Never> in
                presenter.loadUsers(currentUserSex: presenter.viewModel.currentUserSex)
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink { presenter, users in
                
                presenter.checkViewToShow(users: users)
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
            .flatMap({ presenter, _ in
                presenter.getClubIdForCurrentUser()
            })
            .withUnretained(self)
            .sink { presenter, clubId in
            
                presenter.viewModel.currentUserSex = UserDefaults.getUserModel()?.gender ?? "Hombre"
                
                if let clubId = clubId {
                    presenter.viewModel.clubId = clubId
                    
                    presenter.hasMultipleUsersInClub(
                        clubId: clubId,
                        currentDate: presenter.currentDateString!
                    ) { hasMultipleUsers in
                            if !hasMultipleUsers {
                                presenter.viewModel.showNoUsersForClub = true // ❌ Está solo en el club
                            } else {
                                
                                 #warning("TODO: these 2 lines for testing, comment if else below")
                                presenter.viewModel.loadingUsers = true
                                presenter.loadUsersSubject.send()
//                                
                                
                                // 🔹 Si hay más usuarios, validamos el horario
//                                let calendar = Calendar.current
//                                let currentHour = calendar.component(.hour, from: Date())
//                                
//                                if (10...23).contains(currentHour) || (0...2).contains(currentHour) {
//                                    // ✅ Dentro del horario permitido
//                                    presenter.viewModel.loadingUsers = true
//                                     presenter.loadUsersSubject.send()
//                                } else {
//                                    presenter.showOutsideScheduleDialog() // ❌ Fuera de horario
//                                }
                            }
                        }
                } else {
                    presenter.viewModel.showAlert = true
                    presenter.viewModel.shouldOpenConfig = false
                    presenter.viewModel.alertTitle = "Confirmar asistencia"
                    presenter.viewModel.alertMessage = "No tienes asistencia para eventos hoy."
                    presenter.viewModel.alertButtonText = "ACEPTAR"
                }
            }
            .store(in: &cancellables)
        
    }
   
    private func showOutsideScheduleDialog() {
        viewModel.showAlert = true
        viewModel.shouldOpenConfig = false
        viewModel.alertTitle = "Fuera de horario"
        viewModel.alertMessage = "Solo puedes acceder a las fotos de los demás entre las 21:00 y las 00:00."
        viewModel.alertButtonText = "ACEPTAR"
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
                    
                    let assistanceRef = clubSnapshot
                        .childSnapshot(forPath: "Assistance")
                        .childSnapshot(forPath: self.currentDateString!)
                        .childSnapshot(forPath: uid)
                    
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
    
    private func loadUsers(currentUserSex: String) -> AnyPublisher<[TinderUser]?, Never> {
        
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return Just([]).eraseToAnyPublisher()
        }
        
        return useCases.userDataUseCase.getUserInfo(uid: currentUserId)
            .map { userModel in
                if let liked = userModel?.Liked?.keys {
                    return Array(liked)
                } else {
                    return []
                }
            }
            .eraseToAnyPublisher()
            .withUnretained(self)
            .flatMap { presenter, likedUsers -> AnyPublisher<([ClubAssistance], [String]), Never> in
                return presenter.getAssistance()
                    .map { users in
                        print("users")
                        print(users)
                        print("likedUsers")
                        print(likedUsers)
                        return (users, likedUsers)
                    }
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .flatMap { presenter, data -> AnyPublisher<[TinderUser]?, Never> in
                presenter.loadUsersDetails(
                    users: data.0,
                    likedUsers: data.1
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func loadUsersDetails(users: [ClubAssistance], likedUsers: [String]) -> AnyPublisher<[TinderUser]?, Never> {

        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return Just(nil).eraseToAnyPublisher()
        }
       
        let otherSexUsers = users
            .filter({ $0.uid != currentUserId })
            .filter({ $0.gender != viewModel.currentUserSex })
        
        print("Ya ha visto todos los matches")
        if otherSexUsers.isEmpty && !likedUsers.isEmpty {
            print("Mostrar endView")
            return Just([]).eraseToAnyPublisher()
        } else if otherSexUsers.isEmpty && likedUsers.isEmpty {
            print("Mostrar noUsersView")
            return Just(nil).eraseToAnyPublisher()
        }
        
        let usersToLoad = otherSexUsers.filter { user in
            print("filtrando liked users")
            return !likedUsers.contains(where: { $0 == user.uid }) //Filter liked users
        }
        
        let publishers: [AnyPublisher<TinderUser?, Never>] = usersToLoad.map { [weak self] user in

            guard let self = self else {
                return Just(nil).eraseToAnyPublisher()
            }
            
            return self.useCases.userDataUseCase.getUserInfo(uid: user.uid)
                .compactMap({ userModel -> TinderUser? in
                    
                    guard let userModel = userModel else {
                        return nil
                    }
                    if userModel.social?.lowercased() == "no participando" ||
                        userModel.image == nil
                    {
                        print("usuario con uid \(userModel.uid) sin imagen o no participando")
                        return nil
                    } else {
                        print("usuario con uid \(userModel.uid) añadido")
                        return TinderUser(
                            uid: userModel.uid,
                            name: userModel.username,
                            image: userModel.image!
                        )
                    }
                })
                .compactMap({ $0 })
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map({ $0 as? [TinderUser] })
            .eraseToAnyPublisher()
    }
    
    
    func hasMultipleUsersInClub(clubId: String, currentDate: String, completion: @escaping (Bool) -> Void) {
        let assistanceRef = FirebaseServiceImpl.shared.getAssistance(profileId: clubId).child(currentDate)
        
        assistanceRef.observeSingleEvent(of: .value) { snapshot in
            let totalUsers = snapshot.childrenCount
            print("Usuarios totales que van al club = mas de 1 \(totalUsers > 1)")
            completion(totalUsers > 1)
        } withCancel: { error in
            print("Numero usuarios totales que van al club 1 o menos, Error")
            completion(false)
        }
    }
    
    func getAssistance() -> AnyPublisher<[ClubAssistance], Never> {
        
        print("Mirando asistencia del dia \(String(describing: currentDateString))")
        
        let assistanceRef = FirebaseServiceImpl.shared.getAssistance(profileId: self.viewModel.clubId).child(currentDateString!)
        
        return Future<[ClubAssistance], Never> { promise in
            
            assistanceRef.observeSingleEvent(of: .value) { assistanceSnapshot in
                let allUsers = assistanceSnapshot.children.allObjects as! [DataSnapshot]
                
                if allUsers.isEmpty {
                    promise(.success([]))
                }
                
                let assistance = allUsers.compactMap { ClubAssistance(snapshot: $0) }
                
                promise(.success(assistance))
            }
        }
        .eraseToAnyPublisher()
        
    }
}
