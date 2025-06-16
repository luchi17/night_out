//
//  NightOutTests.swift
//  NightOutTests
//
//  Created by Apple on 27/9/24.
//

import XCTest
import Combine

@testable import NightOut

final class TinderPresenterTests: XCTestCase {
    
    func test_checkViewToShow_nilUsers_setsShowNoUsersForClub() {
        // Arrange
        let presenter = TinderPresenterImpl(
            useCases: mockUseCases(),
            actions: TinderPresenterImpl.Actions(goBack: {}, openProfile: {})
        )
        
        // Act
        presenter.checkViewToShow(users: nil)
        
        // Assert
        XCTAssertTrue(presenter.viewModel.showNoUsersForClub)
        XCTAssertFalse(presenter.viewModel.showEndView)
        XCTAssertFalse(presenter.viewModel.loadingUsers)
    }
    
    func test_checkViewToShow_emptyUsers_setsShowEndView() {
        let presenter = TinderPresenterImpl(
            useCases: mockUseCases(),
            actions: TinderPresenterImpl.Actions(goBack: {}, openProfile: {})
        )
        
        presenter.checkViewToShow(users: [])
        
        XCTAssertTrue(presenter.viewModel.showEndView)
        XCTAssertFalse(presenter.viewModel.showNoUsersForClub)
        XCTAssertFalse(presenter.viewModel.loadingUsers)
    }

    func test_checkViewToShow_validUsers_setsUsers() {
        let presenter = TinderPresenterImpl(
            useCases: mockUseCases(),
            actions: TinderPresenterImpl.Actions(goBack: {}, openProfile: {})
        )
        
        let mockUser = TinderUser(uid: "1", name: "Alice", image: "img")
        presenter.checkViewToShow(users: [mockUser])
        
        XCTAssertEqual(presenter.viewModel.users.count, 1)
        XCTAssertFalse(presenter.viewModel.showEndView)
        XCTAssertFalse(presenter.viewModel.showNoUsersForClub)
    }
}

private func mockUseCases() -> TinderPresenterImpl.UseCases {
    let userUseCase = MockUserDataUseCase()
    let clubUseCase = MockClubUseCase()
    return .init(userDataUseCase: userUseCase, clubUseCase: clubUseCase)
}

private final class MockUserDataUseCase: UserDataUseCase {
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
    func findUserByEmail(_ email: String) -> AnyPublisher<UserModel?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }
}

final class MockClubUseCase: ClubUseCase {
    func observeAssistance(profileId: String) -> AnyPublisher<[String : NightOut.ClubAssistance], Never> {
        Just([:]).eraseToAnyPublisher()
    }
    
    func removeAssistingToClub(clubId: String) -> AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }
    
    func addAssistingToClub(clubId: String, clubAssistance: NightOut.ClubAssistance) -> AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }
    
    func getAssistance(profileId: String) -> AnyPublisher<[String : NightOut.ClubAssistance], Never> {
        Just([:]).eraseToAnyPublisher()
    }
}
