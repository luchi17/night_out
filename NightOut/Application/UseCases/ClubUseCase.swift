import Combine

protocol ClubUseCase {
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
}

struct ClubUseCaseImpl: ClubUseCase {
    private let repository: ClubRepository

    init(repository: ClubRepository) {
        self.repository = repository
    }

    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never> {
        return repository
            .observeAssistance(profileId: profileId)
            .eraseToAnyPublisher()
    }
}


