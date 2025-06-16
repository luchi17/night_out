import Combine
import FirebaseAuth

public protocol FollowUseCase {
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never>
    func rejectFollowRequest(requesterUid: String)
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never>
    func addFollow(requesterProfileUid: String, profileUid: String, needRemoveFromPending: Bool) -> AnyPublisher<Bool, Never>
    func removeFollow(requesterProfileUid: String, profileUid: String) -> AnyPublisher<Bool, Never>
    func addPendingRequest(otherUid: String)
    func removePending(otherUid: String)
}

struct FollowUseCaseImpl: FollowUseCase {
    private let repository: PostsRepository

    init(repository: PostsRepository) {
        self.repository = repository
    }

    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return repository.fetchFollow(id: id)
    }
    
    func rejectFollowRequest(requesterUid: String) {
        repository.rejectFollowRequest(requesterUid: requesterUid)
    }
    
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        repository.observeFollow(id: id)
    }
    
    func addFollow(requesterProfileUid: String, profileUid: String, needRemoveFromPending: Bool) -> AnyPublisher<Bool, Never> {
        return repository.addFollow(requesterProfileUid: requesterProfileUid, profileUid: profileUid, needRemoveFromPending: needRemoveFromPending)
    }
    
    func removeFollow(requesterProfileUid: String, profileUid: String) -> AnyPublisher<Bool, Never> {
        return repository.removeFollow(requesterProfileUid: requesterProfileUid, profileUid: profileUid)
    }
    
    func addPendingRequest(otherUid: String) {
        return repository.addPendingRequest(otherUid: otherUid)
    }
    
    func removePending(otherUid: String) {
        return repository.addPendingRequest(otherUid: otherUid)
    }
}


