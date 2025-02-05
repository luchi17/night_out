import Combine

protocol ChatUseCase {
    func getChats(fromUid: String, toUid: String) -> AnyPublisher<[MessageModel], Never>
    func sendMessage(currentUserUid: String, toUid: String, text: String) -> AnyPublisher<Bool, Never>
}

struct ChatUseCaseImpl: ChatUseCase {
    private let repository: ChatRepository

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func getChats(fromUid: String, toUid: String) -> AnyPublisher<[MessageModel], Never> {
        repository
            .getChats(fromUid: fromUid, toUid: toUid)
        
    }
    
    func sendMessage(currentUserUid: String, toUid: String, text: String) -> AnyPublisher<Bool, Never> {
        repository
            .sendMessage(currentUserUid: currentUserUid, toUid: toUid, text: text)
    }
}


