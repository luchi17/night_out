import XCTest
import Combine

@testable import NightOut

final class MockFollowUseCase: FollowUseCase {
    
    func rejectFollowRequest(requesterUid: String) {
    }
    
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return Just(followModelToReturn).eraseToAnyPublisher()
    }
    
    func addFollow(requesterProfileUid: String, profileUid: String, needRemoveFromPending: Bool) -> AnyPublisher<Bool, Never> {
        return Just(true).eraseToAnyPublisher()
    }
    
    func removeFollow(requesterProfileUid: String, profileUid: String) -> AnyPublisher<Bool, Never> {
        return Just(true).eraseToAnyPublisher()
    }
    
    func addPendingRequest(otherUid: String) {
    }
    
    func removePending(otherUid: String) {
    }
    
    var followModelToReturn: FollowModel?
    
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return Just(followModelToReturn).eraseToAnyPublisher()
    }
}

private final class MockUserDataUseCase: UserDataUseCase {
    func findUserByEmail(_ email: String) -> AnyPublisher<UserModel?, Never> {
        return Just(userModelToReturn).eraseToAnyPublisher()
    }
    
    var userModelToReturn: UserModel?
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never> {
        return Just(userModelToReturn).eraseToAnyPublisher()
    }
}

enum MockUserDefaults {
    static var userModel: UserModel? = nil
    static var companyUserModel: UserModel? = nil
    
    static func getUserModel() -> UserModel? { userModel }
    static func getCompanyUserModel() -> UserModel? { companyUserModel }
}



final class MyUserProfilePresenterTests: XCTestCase {

    var cancellables: Set<AnyCancellable> = []
    
    func test_goToLogin_triggersBackToLogin() {
        let followUseCase = MockFollowUseCase()
        let userDataUseCase = MockUserDataUseCase()
        var didNavigateToLogin = false

        let presenter = MyUserProfilePresenterImpl(
            useCases: .init(followUseCase: followUseCase, userDataUseCase: userDataUseCase),
            actions: .init(backToLogin: { didNavigateToLogin = true })
        )

        let viewDidLoad = PassthroughSubject<Void, Never>()
        let goToLogin = PassthroughSubject<Void, Never>()

        let input = MyUserProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoad.eraseToAnyPublisher(),
            goToLogin: goToLogin.eraseToAnyPublisher()
        )

        presenter.transform(input: input)

        goToLogin.send(())

        XCTAssertTrue(didNavigateToLogin)
    }

}

