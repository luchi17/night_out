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
                //TODO: Move to next user
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
                
                presenter.viewModel.showAlert = true
                presenter.viewModel.shouldOpenConfig = true
                presenter.viewModel.alertTitle = "Género"
                presenter.viewModel.alertMessage = "Debes seleccionar el género en los ajustes de tu perfil."
                presenter.viewModel.alertButtonText = "Abrir configuración"
                
//                if data.1 != nil {
//                    presenter.viewModel.users = data.0
//                } else {
//                    presenter.viewModel.showAlert = true
//                    presenter.viewModel.shouldOpenConfig = true
//                    presenter.viewModel.alertTitle = "Género"
//                    presenter.viewModel.alertMessage = "Debes seleccionar el género en los ajustes de tu perfil."
//                    presenter.viewModel.alertButtonText = "Abrir configuración"
//                }
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
//                        presenter.viewModel.alertTitle = "Fuera de horario"
//                        presenter.viewModel.alertMessage = "Solo puedes acceder a las fotos de los demás entre las 21:00 y las 00:00."
//                    }
                } else {
                    presenter.viewModel.showAlert = true
                    presenter.viewModel.alertTitle = "Confirmar asistencia"
                    presenter.viewModel.alertMessage = "Debes confirmar tu asistencia a un club para continuar."
                }
            }
            .store(in: &cancellables)
        
    }
    
    func getClubIdForCurrentUser() -> AnyPublisher<String?, Never> {
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
                promise(.success(nil)) // Manejo de error
            }
        }
        .eraseToAnyPublisher()
    }
}
