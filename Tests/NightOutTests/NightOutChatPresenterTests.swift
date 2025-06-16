
//  NightOutChatPresenterTests.swift
//  NightOut
//
//  Created by Apple on 16/6/25.


import XCTest
import Combine
@testable import NightOut

final class MockChatUseCase: ChatUseCase {
    var getChatsResult: [MessageModel] = []
    var sendMessageResult: Bool = true
    
    func getChats(fromUid: String, toUid: String) -> AnyPublisher<[MessageModel], Never> {
        return Just(getChatsResult).eraseToAnyPublisher()
    }
    
    func sendMessage(currentUserUid: String, toUid: String, text: String) -> AnyPublisher<Bool, Never> {
        return Just(sendMessageResult).eraseToAnyPublisher()
    }
}

private final class MockFollowUseCase: FollowUseCase {
    func rejectFollowRequest(requesterUid: String) {
    }
    
    func observeFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return Just(nil).eraseToAnyPublisher()
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
    
    func fetchFollow(id: String) -> AnyPublisher<FollowModel?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }
}

private final class MockUserDataUseCase: UserDataUseCase {
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never> {
        let user = UserModel(uid: uid, fullname: "User One", username: "user1", email: "", image: nil, profile: "public")
        return Just(user).eraseToAnyPublisher()
    }
    
    func findUserByEmail(_ email: String) -> AnyPublisher<UserModel?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }
}

private final class MockCompanyDataUseCase: CompanyDataUseCase {
    func getCompanyInfo(uid: String) -> AnyPublisher<CompanyModel?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }
}

final class ChatPresenterTests: XCTestCase {
    
    var presenter: ChatPresenterImpl!
    var chatUseCase: MockChatUseCase!
    fileprivate var followUseCase: MockFollowUseCase!
    fileprivate var userDataUseCase: MockUserDataUseCase!
    fileprivate var companyDataUseCase: MockCompanyDataUseCase!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        chatUseCase = MockChatUseCase()
        followUseCase = MockFollowUseCase()
        userDataUseCase = MockUserDataUseCase()
        companyDataUseCase = MockCompanyDataUseCase()
        cancellables = []
        
        let useCases = ChatPresenterImpl.UseCases(
            chatUseCase: chatUseCase,
            followUseCase: followUseCase,
            userDataUseCase: userDataUseCase,
            companyDataUseCase: companyDataUseCase
        )
        
        let actions = ChatPresenterImpl.Actions(
            goBack: {},
            goToProfile: { _ in },
            goToPrivateProfile: { _ in }
        )
        
        let chat = Chat(otherUserUid: "uid2", username: "otherUser", lastMessage: "", profileImage: "")
        
        presenter = ChatPresenterImpl(useCases: useCases, actions: actions, chat: chat, firebaseService: MockFirebaseService())
    }
    
    func testViewDidLoadLoadsMessages() {
        // Preparamos mensajes mock
        let mockMessages = [
            MessageModel(id: "msg1", message: "Hola", sender: "uid1", timestamp: Int64(Date().timeIntervalSince1970))
        ]
        chatUseCase.getChatsResult = mockMessages
        
        // Input
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let input = ChatPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            goBack: Empty().eraseToAnyPublisher(),
            sendMessage: Empty().eraseToAnyPublisher(),
            goToProfile: Empty().eraseToAnyPublisher()
        )
        
        presenter.transform(input: input)
        
        let expect = expectation(description: "messages loaded")
        
        presenter.viewModel.$messages
            .dropFirst()
            .sink { messages in
                if messages.count == 1 && messages.first?.message == "Hola" {
                    expect.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewDidLoadSubject.send(())
        
        waitForExpectations(timeout: 1)
    }
}
