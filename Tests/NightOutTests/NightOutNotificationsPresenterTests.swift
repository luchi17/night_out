//
//  NightOutPayDetailPresenter.swift
//  NightOut
//
//  Created by Apple on 16/6/25.
//


import XCTest
import Combine
@testable import NightOut


// Mocks

final class MockNotificationsUseCase: NotificationsUseCase {
    var notificationsToReturn: [String: NotificationModel] = [:]
   
    func observeNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never> {
        return Just(notificationsToReturn).eraseToAnyPublisher()
    }
    func fetchNotifications(publisherId: String) -> AnyPublisher<[String: NotificationModel], Never> {
        Just([:]).eraseToAnyPublisher()
    }
    func addNotification(model: NotificationModel, publisherId: String) -> AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }
    func removeNotification(userId: String, notificationId: String) { }
    func sendNotificationToFollowers(myName: String, clubName: String) { }
}

private final class MockUserDataUseCase: UserDataUseCase {
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never> {
        let user = UserModel(uid: uid, fullname: "User One", username: "user1", email: "", image: nil, profile: "private")
        return Just(user).eraseToAnyPublisher()
    }
    
    func findUserByEmail(_ email: String) -> AnyPublisher<UserModel?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }
}

private final class MockFollowUseCase: FollowUseCase {
    func addFollow(requesterProfileUid: String, profileUid: String, needRemoveFromPending: Bool) -> AnyPublisher<Bool, Never> {
        return Just(true).eraseToAnyPublisher()
    }
    
    func rejectFollowRequest(requesterUid: String) {
        // no-op
    }
    
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }
    
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }
    func addPendingRequest(otherUid: String) {
    }
    func removePending(otherUid: String) { }
    
    func removeFollow(requesterProfileUid: String, profileUid: String) -> AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }
}

final class MockPostsUseCase: PostsUseCase {
    
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never> {
        return Just([:]).eraseToAnyPublisher()
    }
    func observePosts() -> AnyPublisher<[String: PostUserModel]?, Never> {
        return Just([:]).eraseToAnyPublisher()
    }
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }
    func getComments(postId: String) -> AnyPublisher<[CommentModel], Never> {
        return Just([]).eraseToAnyPublisher()
    }
    func addComment(comment: CommentModel, postId: String) -> AnyPublisher<Bool, Never> {
        return Just(true).eraseToAnyPublisher()
    }
}


final class NotificationsPresenterTests: XCTestCase {
    var presenter: NotificationsPresenterImpl!
    var notificationsUseCase: MockNotificationsUseCase!
    fileprivate var userDataUseCase: MockUserDataUseCase!
    fileprivate var followUseCase: MockFollowUseCase!
    var postsUseCase: MockPostsUseCase!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        notificationsUseCase = MockNotificationsUseCase()
        userDataUseCase = MockUserDataUseCase()
        followUseCase = MockFollowUseCase()
        postsUseCase = MockPostsUseCase()
        cancellables = []

        let useCases = NotificationsPresenterImpl.UseCases(
            notificationsUseCase: notificationsUseCase,
            userDataUseCase: userDataUseCase,
            followUseCase: followUseCase,
            postsUseCase: postsUseCase
        )

        let actions = NotificationsPresenterImpl.Actions(
            goToProfile: { _ in },
            goToPrivateProfile: { _ in },
            goToPost: { _ in },
            goBack: { }
        )
        
        // MockFirebaseService que devuelva UID fijo para el test
        presenter = NotificationsPresenterImpl(
            useCases: useCases,
            actions: actions,
            firebaseService: MockFrebaseService(uid: "user123")
        )
    }

    func testLoadNotificationsOnViewDidLoad() {
        // Preparar input
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()

        // Notificación mock
        let notificationModel = NotificationModel(
            ispost: false,
            postid: "post1",
            text: GlobalStrings.shared.followUserText,
            userid: "user1", // coincide con uid del MockFirebaseService
            timestamp: Int64(Date().timeIntervalSince1970)
        )
        notificationsUseCase.notificationsToReturn = ["notif1": notificationModel]

        let input = NotificationsPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            accept: Empty().eraseToAnyPublisher(),
            reject: Empty().eraseToAnyPublisher(),
            goToPost: Empty().eraseToAnyPublisher(),
            goToProfile: Empty().eraseToAnyPublisher(),
            goBack: Empty().eraseToAnyPublisher()
        )

        presenter.transform(input: input)

        let expectation = expectation(description: "notifications loaded")

        presenter.viewModel.$notifications
            .dropFirst()
            .sink { notifications in
                if notifications.count == 1,
                   notifications.first?.userName == "user1" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Simular viewDidLoad
        viewDidLoadSubject.send(())

        waitForExpectations(timeout: 1)
    }
}


// MockFirebaseService simple para el test
private final class MockFrebaseService: FirebaseServiceProtocol {
    func getImUser() -> Bool {
        return true
    }
    
    private let uid: String?

    init(uid: String?) {
        self.uid = uid
    }

    func getCurrentUserUid() -> String? {
        return uid
    }
}
