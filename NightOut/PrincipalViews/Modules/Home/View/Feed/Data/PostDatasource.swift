import Combine
import GoogleSignIn
import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import FirebaseStorage


protocol PostDatasource {
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never>
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never>
    func getComments(postId: String) -> AnyPublisher<[String: CommentModel], Never>
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never>
    func acceptFollowRequest(requesterUid: String) -> AnyPublisher<Bool, Never>
    func rejectFollowRequest(requesterUid: String)
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never>
   
}

struct PostDatasourceImpl: PostDatasource {
    
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never> {
        
        let publisher = PassthroughSubject<[String: PostUserModel], Never>()
        
        let ref = FirebaseServiceImpl.shared.getPosts()
        
        ref.getData { error, snapshot in
            guard error == nil else {
                print("Error fetching data: \(error!.localizedDescription)")
                publisher.send([:])
                return
            }
            
            do {
                if let allFollowModel = try snapshot?.data(as: [String: PostUserModel].self) {
                    publisher.send(allFollowModel)
                } else {
                    publisher.send([:])
                }
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                publisher.send([:])
            }
            
            
        }
        return publisher.eraseToAnyPublisher()
    }
    
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return Future<FollowModel?, Never> { promise in
            
            let ref = FirebaseServiceImpl.shared.getFollow().child(id)
            
            ref.getData { error, snapshot in
                guard error == nil else {
                    print("Error fetching data: \(error!.localizedDescription)")
                    promise(.success(nil))
                    return
                }
                
                do {
                    if let followModel = try snapshot?.data(as: FollowModel.self) {
                        promise(.success(followModel))
                        UserDefaults.setFollowModel(followModel)
                    } else {
                        promise(.success(nil))
                    }
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Observando cambios en firebase
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        let subject = CurrentValueSubject<FollowModel?, Never>(nil)
        
        let ref = FirebaseServiceImpl.shared.getFollow().child(id)
        
        ref.observe(.value) { snapshot in
            do {
                let followModel = try snapshot.data(as: FollowModel.self)
                subject.send(followModel)
                UserDefaults.setFollowModel(followModel)
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                subject.send(nil)
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    
    func getComments(postId: String) -> AnyPublisher<[String: CommentModel], Never> {
        return Future<[String: CommentModel], Never> { promise in
            let ref = FirebaseServiceImpl.shared.getComments().child(postId)
            
            ref.getData { error, snapshot in
                guard error == nil else {
                    print("Error fetching data: \(error!.localizedDescription)")
                    promise(.success([:]))
                    return
                }
                
                do {
                    if let comments = try snapshot?.data(as: [String: CommentModel].self) {
                        promise(.success(comments))
                    } else {
                        promise(.success([:]))
                    }
                } catch {
                    print("Error decoding data: \(error.localizedDescription)")
                    promise(.success([:]))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { promise in
            
            let commentData = structToDictionary(comment)
            let ref = FirebaseServiceImpl.shared.getComments().child(postId)
            
            ref.childByAutoId().setValue(commentData) { error, _ in
                if let error = error {
                    print("Error al guardar el comentario en la base de datos: \(error.localizedDescription)")
                    promise(.success(false))
                } else {
                    print("Comentario guardado exitosamente en la base de datos")
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
        
    }
    
    func acceptFollowRequest(requesterUid: String) -> AnyPublisher<Bool, Never> {
        
        return Future<Bool, Never> { promise in
            
            guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                return promise(.success(false))
            }
            
            let ref = FirebaseServiceImpl.shared.getFollow().child(currentUserId).child("Followers").child(requesterUid)
            
            ref.setValue(true) { error, _ in
                if let error = error {
                    print("Error al guardar el comentario en la base de datos: \(error.localizedDescription)")
                    promise(.success(false))
                } else {
                    print("Comentario guardado exitosamente en la base de datos")
                    let reverseFollowRef = FirebaseServiceImpl.shared.getFollow().child(requesterUid).child("Following").child(currentUserId)
                    reverseFollowRef.setValue(true) { error, _ in
                        if error == nil {
                            self.removePendingRequest(requesterUid: requesterUid, currentUserId: currentUserId)
                            promise(.success(true))
                        } else {
                            promise(.success(false))
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func rejectFollowRequest(requesterUid: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        removePendingRequest(requesterUid: requesterUid, currentUserId: currentUserId)
    }
    
    // Eliminar la solicitud pendiente de seguimiento
    private func removePendingRequest(requesterUid: String, currentUserId: String) {
        let pendingRef = FirebaseServiceImpl.shared.getFollow().child(currentUserId).child("Pending").child(requesterUid)
        pendingRef.removeValue()
    }
    
    
    
}
