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
    func fetchFollow() -> AnyPublisher<FollowModel?, Never>
    func getComments(postId: String) -> AnyPublisher<[String: CommentModel], Never>
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never>
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
    
    func fetchFollow() -> AnyPublisher<FollowModel?, Never> {
        return Future<FollowModel?, Never> { promise in
            
            guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                promise(.success(nil))
                return
            }
            
            let ref = FirebaseServiceImpl.shared.getFollow()
            
            ref.getData { error, snapshot in
                guard error == nil else {
                    print("Error fetching data: \(error!.localizedDescription)")
                    promise(.success(nil))
                    return
                }
                
                do {
                    if let allFollowModel = try snapshot?.data(as: [String: FollowModel].self) {
                        promise(.success(allFollowModel[uid]))
                        if let followModel = allFollowModel[uid] {
                            UserDefaults.setFollowModel(followModel)
                        }
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
            
            ref.setValue(commentData) { error, _ in
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
    
}
