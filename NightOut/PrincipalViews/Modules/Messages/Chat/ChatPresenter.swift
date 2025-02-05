import SwiftUI
import Combine
import FirebaseDatabase

final class ChatViewModel: ObservableObject {
    @Published var messages: [MessageModel] = []
    @Published var otherUsername: String = ""
    @Published var newMessage: String = ""
    @Published var myUid: String = ""
    @Published var loading: Bool = true
    @Published var toast: ToastType?
    
    init(otherUsername: String, myUid: String) {
        self.otherUsername = otherUsername
        self.myUid = myUid
    }
}

protocol ChatPresenter {
    var viewModel: ChatViewModel { get }
    func transform(input: ChatPresenterImpl.ViewInputs)
}

final class ChatPresenterImpl: ChatPresenter {
    
    struct UseCases {
        let chatUseCase: ChatUseCase
    }
    
    struct Actions {
        let goBack: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
        let sendMessage: AnyPublisher<Void, Never>
    }
    
    var viewModel: ChatViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    let chat: Chat
    
    init(
        useCases: UseCases,
        actions: Actions,
        chat: Chat
    ) {
        self.actions = actions
        self.useCases = useCases
        self.chat = chat
        
        viewModel = ChatViewModel(otherUsername: chat.username, myUid: FirebaseServiceImpl.shared.getCurrentUserUid() ?? "")
    }
    
    func transform(input: ChatPresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .handleEvents(receiveRequest: { [weak self] request in
                self?.viewModel.loading = true
            })
            .flatMap({ presenter, _ -> AnyPublisher<[MessageModel], Never> in
                guard let myUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just([]).eraseToAnyPublisher()
                }
                return presenter.useCases.chatUseCase.getChats(
                    fromUid: myUid,
                    toUid: presenter.chat.otherUserUid
                )
                
            })
            .withUnretained(self)
            .sink { presenter, messages in
                presenter.viewModel.loading = false
                presenter.viewModel.messages = messages
            }
            .store(in: &cancellables)
        
        input
            .sendMessage
            .handleEvents(receiveRequest: { [weak self] request in
                self?.viewModel.loading = true
            })
            .withUnretained(self)
            .flatMap({ presenter, _ -> AnyPublisher<Bool, Never> in
                guard let myUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(false).eraseToAnyPublisher()
                }
        
                return presenter.useCases.chatUseCase.sendMessage(
                    currentUserUid: myUid,
                    toUid: presenter.chat.otherUserUid,
                    text: presenter.viewModel.newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            })
            .withUnretained(self)
            .sink { presenter, sent in
                presenter.viewModel.loading = false
                presenter.viewModel.newMessage = "" // Limpiar mensaje
                if !sent {
                    presenter.viewModel.toast = .custom(.init(title: "Error", description: "Error al cargar mensajes.", image: nil))
                }
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
}
