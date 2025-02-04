import SwiftUI
import Combine
import FirebaseDatabase

final class MessagesViewModel: ObservableObject {
    @Published var chatList: [Chat] = []
    @Published var loading: Bool = true
    @Published var toast: ToastType?
}

protocol MessagesPresenter {
    var viewModel: MessagesViewModel { get }
    func transform(input: MessagesPresenterImpl.ViewInputs)
}

final class MessagesPresenterImpl: MessagesPresenter {
    
    struct UseCases {
    }
    
    struct Actions {
        let goToChat: InputClosure<Chat>
        let goBack: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let goToChat: AnyPublisher<Chat, Never>
        let goBack: AnyPublisher<Void, Never>
    }
    
    var viewModel: MessagesViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = MessagesViewModel()
    }
    
    func transform(input: MessagesPresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.fetchChats()
            }
            .store(in: &cancellables)
        
        input
            .goToChat
            .withUnretained(self)
            .sink { presenter, chat in
                presenter.actions.goToChat(chat)
            }
            .store(in: &cancellables)
        
        input
            .goBack
            .withUnretained(self)
            .sink { presenter, chat in
                presenter.actions.goBack()
            }
            .store(in: &cancellables)
    }
    
    func fetchChats() {
        guard let currentUserUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            self.viewModel.loading = false
            return
        }
        
        let likedUsersRef = Database.database().reference().child("Users/\(currentUserUid)/Liked")
        
        likedUsersRef.observeSingleEvent(of: .value) { [weak self] likedUsersSnapshot in
            guard let self = self else {
                return
            }
            guard likedUsersSnapshot.exists() else {
                self.viewModel.chatList = []
                self.viewModel.loading = false
                return
            }
            
            var fetchedChats: [Chat] = []
            let group = DispatchGroup()
            
            // Recorrer cada usuario que has dado like (cada UID)
            for likedUserSnapshot in likedUsersSnapshot.children {
                
                guard let likedUserSnapshot = likedUserSnapshot as? DataSnapshot,
                      let likedUserUid = likedUserSnapshot.key as String? else {
                    continue
                }
                
                group.enter()
                
                // Verificar si el usuario también ha dado like al usuario actual
                let likedByUserRef = FirebaseServiceImpl.shared.getLikedUsers(fromUid: likedUserUid, toUid: currentUserUid)
                
                likedByUserRef.observeSingleEvent(of: .value) { likedByUserSnapshot in
                    
                    // Solo si el usuario también ha dado like, creamos el chat
                    if likedByUserSnapshot.exists() {
                        
                        // Obtener el nombre del usuario en el nodo Users
                        let userRef = Database.database().reference().child("Users/\(likedUserUid)")

                        userRef.observeSingleEvent(of: .value) { userSnapshot in
                            
                            // Verificar que el usuario existe y tiene un nombre
                            let username = userSnapshot.childSnapshot(forPath: "username").value as? String ?? "Desconocido"
                            let profileImage = userSnapshot.childSnapshot(forPath: "image").value as? String
                            
                            // Obtener el último mensaje para el seguidor
                            let lastMessageRef =
                            FirebaseServiceImpl.shared.getChats(userUid: currentUserUid, likedUserUid: likedUserUid)
                                .queryOrdered(byChild: "timestamp")
                                .queryLimited(toLast: 1)
                           
                            lastMessageRef.observeSingleEvent(of: .value) { lastMessageSnapshot in
                                
                                let lastMessage: String

                                if let firstChild = lastMessageSnapshot.children.allObjects.first as? DataSnapshot {
                                    if let message = firstChild.childSnapshot(forPath: "message").value as? String {
                                        lastMessage = message
                                    } else {
                                        lastMessage = "No hay mensajes"
                                    }
                                } else {
                                    lastMessage = "Inicia una conversación"
                                }
                                
                                // Crear un objeto Chat que contenga el UID del otro usuario y el último mensaje
                                let chat = Chat(
                                    otherUserUid: likedUserUid,
                                    username: username,
                                    lastMessage: lastMessage,
                                    profileImage: profileImage
                                )
                                
                                fetchedChats.append(chat)

                                group.leave()
                                
                            }  withCancel: { [weak self] error in
                                self?.viewModel.toast = .custom(.init(title: "Error", description: "Error al cargar el último mensaje.", image: nil))
                            }
                        } withCancel: { [weak self] error in
                            self?.viewModel.toast = .custom(.init(title: "Error", description: "Error al cargar usuario.", image: nil))
                        }
                        
                    } else {
                        group.leave()
                    }
                }  withCancel: {  [weak self] error in
                    self?.viewModel.toast = .custom(.init(title: "Error", description: "Error al Error al verificar likes.", image: nil))
                }
            }
            
            group.notify(queue: .main) {
                self.viewModel.chatList = fetchedChats
                self.viewModel.loading = false
            }

        }
    }
}

