import Combine
import Foundation
import Firebase

protocol ChatDataSource {
    func getChats(fromUid: String, toUid: String) -> AnyPublisher<[MessageModel], Never>
    func sendMessage(currentUserUid: String, toUid: String, text: String) -> AnyPublisher<Bool, Never>
}

struct ChatDataSourceImpl: ChatDataSource {
    
    func getChats(fromUid: String, toUid: String) -> AnyPublisher<[MessageModel], Never> {
        
        let subject = CurrentValueSubject<[MessageModel], Never>([])
        let ref = FirebaseServiceImpl.shared.getChats(userUid: fromUid, likedUserUid: toUid)
        
        ref.observe(.value) { snapshot in
            var newMessages: [MessageModel] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let message = try? snapshot.data(as: MessageModel.self) {
                    newMessages.append(message)
                }
            }
            subject.send(newMessages.sorted { $0.timestamp < $1.timestamp })
        }
        
        return subject.eraseToAnyPublisher()
        
    }
    
    func sendMessage(currentUserUid: String, toUid: String, text: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { promise in
            
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                promise(.success(false))
                return
            }
                    
            let messageId = FirebaseServiceImpl.shared.getChats(userUid: currentUserUid, likedUserUid: toUid).childByAutoId().key ?? UUID().uuidString
            
            
            let message = MessageModel(
                id: messageId,
                message: text,
                sender: currentUserUid,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000)
            )
            
            let data = structToDictionary(message)
            
            let ref = FirebaseServiceImpl.shared.getChats(userUid: currentUserUid, likedUserUid: toUid).child(messageId)
            
            ref.setValue(data) { error, reference in
                if error != nil {
                    promise(.success(false))
                } else {
                    // Guardar también en la conversación del otro usuario
                    let ref = FirebaseServiceImpl.shared.getChats(userUid: toUid, likedUserUid: currentUserUid).child(messageId)
                    
                    ref.setValue(data) { error, reference in
                        if error != nil {
                            promise(.success(false))
                        } else {
                            promise(.success(true))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
