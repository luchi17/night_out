import Combine
import FirebaseAuth

protocol FollowUseCase {
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never>
}

struct FollowUseCaseImpl: FollowUseCase {
    private let repository: PostsRepository

    init(repository: PostsRepository) {
        self.repository = repository
    }

    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return repository
            .fetchFollow(id: id)
            .eraseToAnyPublisher()
    }
}


