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
    
    func fetchPosts() -> AnyPublisher<[String : PostModel], Never> {
        let post = PostModel(postID: "post1", postImage: "imageURL")
        return Just(["post1": post]).eraseToAnyPublisher()
    }
    
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
        
        presenter = NotificationsPresenterImpl(useCases: useCases, actions: actions, firebaseService: MockFirebaseService())
    }
    
    func testLoadNotificationsOnViewDidLoad() {
        // Preparar input
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        
        let notificationModel = NotificationModel(
                    ispost: false,
                    text: GlobalStrings.shared.followUserText,
                    userid: "user1",
                    postid: "post1",
                    timestamp: 1234567890
                )
        
        notificationsUseCase.notificationsToReturn = ["notif1": notificationModel]
        
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
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
                                    expect.fulfill()
                                }
            }
            .store(in: &cancellables)
        
        // Enviar notificación mockeada
        let notificationModel = NotificationModel(
            ispost: false,
            postid: "",
            text: GlobalStrings.shared.followUserText,
            userid: "user123",
            timestamp: Int64(Date().timeIntervalSince1970)
        )
        
        // Simular viewDidLoad
        viewDidLoadSubject.send(())
        
        waitForExpectations(timeout: 1)
    }
}



