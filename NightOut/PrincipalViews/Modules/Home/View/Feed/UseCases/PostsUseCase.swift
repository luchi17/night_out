import Combine
import FirebaseAuth

protocol PostsUseCase {
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never>
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never>
    func getComments(postId: String) -> AnyPublisher<[String : CommentModel], Never>
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never>
}

struct PostsUseCaseImpl: PostsUseCase {
    private let repository: PostsRepository

    init(repository: PostsRepository) {
        self.repository = repository
    }

    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never> {
        return repository
            .fetchPosts()
            .eraseToAnyPublisher()
    }
    
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return repository
            .fetchFollow(id: id)
            .eraseToAnyPublisher()
    }
    
    func getComments(postId: String) -> AnyPublisher<[String : CommentModel], Never> {
        return repository
            .getComments(postId: postId)
            .eraseToAnyPublisher()
    }
    
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never> {
        return repository
            .addComment(comment: comment, postId: postId)
            .eraseToAnyPublisher()
    }
}

