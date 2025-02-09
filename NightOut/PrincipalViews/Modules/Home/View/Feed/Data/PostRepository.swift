import Combine
import Foundation

protocol PostsRepository {
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never>
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never>
    func getComments(postId: String) -> AnyPublisher<[CommentModel], Never>
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never>
    func rejectFollowRequest(requesterUid: String)
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never>
    func addFollow(requesterProfileUid: String, profileUid: String, needRemoveFromPending: Bool) -> AnyPublisher<Bool, Never>
    func removeFollow(requesterProfileUid: String, profileUid: String) -> AnyPublisher<Bool, Never>
}

struct PostsRepositoryImpl: PostsRepository {
    
    static let shared: PostsRepository = PostsRepositoryImpl()

    private let network: PostDatasource

    init(
        network: PostDatasource = PostDatasourceImpl()
    ) {
        self.network = network
    }
    
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never> {
        network
            .fetchPosts()
            .eraseToAnyPublisher()
    }
    
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        network
            .fetchFollow(id: id)
            .eraseToAnyPublisher()
    }
    
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        network
            .observeFollow(id: id)
            .eraseToAnyPublisher()
    }
    
    func getComments(postId: String) -> AnyPublisher<[CommentModel], Never> {
        return network
            .getComments(postId: postId)
            .eraseToAnyPublisher()
    }
    
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never> {
        return network
            .addComment(comment: comment, postId: postId)
            .eraseToAnyPublisher()
    }
    
    func removeFollow(requesterProfileUid: String, profileUid: String) -> AnyPublisher<Bool, Never> {
        return network
            .removeFollow(requesterProfileUid: requesterProfileUid, profileUid: profileUid)
            .eraseToAnyPublisher()
    }
    
    func addFollow(requesterProfileUid: String, profileUid: String, needRemoveFromPending: Bool) -> AnyPublisher<Bool, Never> {
        return network
            .addFollow(requesterProfileUid: requesterProfileUid, profileUid: profileUid, needRemoveFromPending: needRemoveFromPending)
            .eraseToAnyPublisher()
    }
    
    func rejectFollowRequest(requesterUid: String) {
        network.rejectFollowRequest(requesterUid: requesterUid)
    }
}
