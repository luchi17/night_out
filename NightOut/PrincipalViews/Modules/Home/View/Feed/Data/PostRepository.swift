import Combine
import Foundation

protocol PostsRepository {
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never>
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never>
    func getComments(postId: String) -> AnyPublisher<[String : CommentModel], Never>
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never>
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
    
    
    func getComments(postId: String) -> AnyPublisher<[String : CommentModel], Never> {
        return network
            .getComments(postId: postId)
            .eraseToAnyPublisher()
    }
    
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never> {
        return network
            .addComment(comment: comment, postId: postId)
            .eraseToAnyPublisher()
    }
    
    
}
