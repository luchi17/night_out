import Combine
import FirebaseAuth

protocol PostsUseCase {
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never>
    func fetchFollow() -> AnyPublisher<FollowModel?, Never>
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
    
    func fetchFollow() -> AnyPublisher<FollowModel?, Never> {
        return repository
            .fetchFollow()
            .eraseToAnyPublisher()
    }
}

