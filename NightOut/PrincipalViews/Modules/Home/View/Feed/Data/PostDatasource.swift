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
    func getComments(postId: String) -> AnyPublisher<[CommentModel], Never>
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never>
    func rejectFollowRequest(requesterUid: String)
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never>
    func addFollow(requesterProfileUid: String, profileUid: String, needRemoveFromPending: Bool) -> AnyPublisher<Bool, Never>
    func removeFollow(requesterProfileUid: String, profileUid: String) -> AnyPublisher<Bool, Never>
    func addPendingRequest(otherUid: String)
    func removePendingRequest(requesterUid: String, currentUserId: String)
}

struct PostDatasourceImpl: PostDatasource {
    
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never> {
        
        let subject = CurrentValueSubject<[String: PostUserModel], Never>([:])
        
        let ref = FirebaseServiceImpl.shared.getPosts().queryOrderedByKey()
        
        ref.observe(.value) { snapshot in
            do {
                let posts = try snapshot.data(as: [String: PostUserModel].self)
                subject.send(posts)
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                subject.send([:])
            }
        }
        return subject.eraseToAnyPublisher()
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
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                subject.send(nil)
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    
    func getComments(postId: String) -> AnyPublisher<[CommentModel], Never> {
        return Future<[CommentModel], Never> { promise in
            
            guard !postId.isEmpty else {
                promise(.success([]))
                return
            }
            
            let ref = FirebaseServiceImpl.shared.getComments().child(postId)
            
            ref.observe(.value) { snapshot in
                var comments: [CommentModel] = []
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let comment = try? snapshot.data(as: CommentModel.self) {
                        comments.append(comment)
                    }
                }
                promise(.success(comments))
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

    func addFollow(requesterProfileUid: String, profileUid: String, needRemoveFromPending: Bool) -> AnyPublisher<Bool, Never> {
        
        return Future<Bool, Never> { promise in
            
            let ref = FirebaseServiceImpl.shared.getFollow().child(profileUid).child("Followers").child(requesterProfileUid)
            
            ref.setValue(true) { error, _ in
                if let error = error {
                    print("Error al guardar el comentario en la base de datos: \(error.localizedDescription)")
                    promise(.success(false))
                } else {
                    print("Comentario guardado exitosamente en la base de datos")
                    let reverseFollowRef = FirebaseServiceImpl.shared.getFollow().child(requesterProfileUid).child("Following").child(profileUid)
                    reverseFollowRef.setValue(true) { error, _ in
                        if error == nil {
                            if needRemoveFromPending {
                                self.removePendingRequest(requesterUid: requesterProfileUid, currentUserId: profileUid)
                            }
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
    
    func removeFollow(requesterProfileUid: String, profileUid: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { promise in
            
            let ref = FirebaseServiceImpl.shared.getFollow().child(profileUid).child("Followers").child(requesterProfileUid)
            
            ref.removeValue() { error, _ in
                if let error = error {
                    print("Error al guardar el comentario en la base de datos: \(error.localizedDescription)")
                    promise(.success(false))
                } else {
                    print("Comentario guardado exitosamente en la base de datos")
                    let reverseFollowRef = FirebaseServiceImpl.shared.getFollow().child(requesterProfileUid).child("Following").child(profileUid)
                    reverseFollowRef.removeValue() { error, _ in
                        if error == nil {
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
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        removePendingRequest(requesterUid: requesterUid, currentUserId: currentUserId)
    }
    
    // Eliminar la solicitud pendiente de seguimiento
    func removePendingRequest(requesterUid: String, currentUserId: String) {
        let pendingRef = FirebaseServiceImpl.shared.getFollow().child(currentUserId).child("Pending").child(requesterUid)
        pendingRef.removeValue()
    }
    
    func addPendingRequest(otherUid: String) {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let pendingRef = FirebaseServiceImpl.shared.getFollow().child(otherUid).child("Pending").child(currentUserId)
        pendingRef.setValue(true)
    }
}
