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
        let publisher = PassthroughSubject<FollowModel?, Never>()
        
        guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            publisher.send(nil)
            return publisher.eraseToAnyPublisher()
        }
        
        let ref = FirebaseServiceImpl.shared.getFollow()
        
        ref.getData { error, snapshot in
            guard error == nil else {
                print("Error fetching data: \(error!.localizedDescription)")
                publisher.send(nil)
                return
            }
            
            do {
                if let allFollowModel = try snapshot?.data(as: [String: FollowModel].self) {
                    publisher.send(allFollowModel[uid])
                    if let followModel = allFollowModel[uid] {
                        UserDefaults.setFollowModel(followModel)
                    }
                } else {
                    publisher.send(nil)
                }
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
                publisher.send(nil)
            }
        }
        
        return publisher.eraseToAnyPublisher()
        
    }
    
}
