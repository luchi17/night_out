import Combine
import Foundation

protocol ChatRepository {
    func getChats(fromUid: String, toUid: String) -> AnyPublisher<[MessageModel], Never>
    func sendMessage(currentUserUid: String, toUid: String, text: String) -> AnyPublisher<Bool, Never>
}

struct ChatRepositoryImpl: ChatRepository {
    
    static let shared: ChatRepository = ChatRepositoryImpl()

    private let network: ChatDataSource

    init(
        network: ChatDataSource = ChatDataSourceImpl()
    ) {
        self.network = network
    }
    
    func getChats(fromUid: String, toUid: String) -> AnyPublisher<[MessageModel], Never> {
        network
            .getChats(fromUid: fromUid, toUid: toUid)
        
    }
    
    func sendMessage(currentUserUid: String, toUid: String, text: String) -> AnyPublisher<Bool, Never> {
        network
            .sendMessage(currentUserUid: currentUserUid, toUid: toUid, text: text)
    }
    
   
}
