import Combine
import FirebaseAuth

protocol FollowUseCase {
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never>
    func acceptFollowRequest(requesterUid: String) -> AnyPublisher<Bool, Never>
    func rejectFollowRequest(requesterUid: String)
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never>
}

struct FollowUseCaseImpl: FollowUseCase {
    private let repository: PostsRepository

    init(repository: PostsRepository) {
        self.repository = repository
    }

    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return repository.fetchFollow(id: id)
    }
    
    func acceptFollowRequest(requesterUid: String) -> AnyPublisher<Bool, Never> {
        return repository.acceptFollowRequest(requesterUid: requesterUid)
    }
    
    func rejectFollowRequest(requesterUid: String) {
        repository.rejectFollowRequest(requesterUid: requesterUid)
    }
    
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        repository.observeFollow(id: id)
    }
}


