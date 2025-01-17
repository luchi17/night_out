import Combine

protocol ClubUseCase {
    func observeAssistance(profileId: String) -> AnyPublisher<[String: ClubAssistance], Never>
    func removeAssistingToClub(clubId: String) -> AnyPublisher<Bool, Never>
    func addAssistingToClub(clubId: String, clubAssistance: ClubAssistance) -> AnyPublisher<Bool, Never>
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
    
    func removeAssistingToClub(clubId: String) -> AnyPublisher<Bool, Never> {
        return repository
            .removeAssistingToClub(clubId: clubId)
            .eraseToAnyPublisher()
    }
    
    func addAssistingToClub(clubId: String, clubAssistance: ClubAssistance) -> AnyPublisher<Bool, Never> {
        return repository
            .addAssistingToClub(clubId: clubId, clubAssistance: clubAssistance)
            .eraseToAnyPublisher()
    }
}


