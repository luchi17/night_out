//
//  NightOutTests.swift
//  NightOutTests
//
//  Created by Apple on 27/9/24.
//

import XCTest
import Combine
@testable import NightOut

final class MockLeaguesUserDataUseCase: UserDataUseCase {
    var userInfoSubject = PassthroughSubject<UserModel?, Never>()
    
    func getUserInfo(uid: String) -> AnyPublisher<UserModel?, Never> {
        return userInfoSubject.eraseToAnyPublisher()
    }
    var userModelToReturn: UserModel?
    func findUserByEmail(_ email: String) -> AnyPublisher<UserModel?, Never> {
        return Just(userModelToReturn).eraseToAnyPublisher()
    }
}

final class MockCompanyDataUseCase: CompanyDataUseCase {
    
    func getCompanyInfo(uid: String) -> AnyPublisher<CompanyModel?, Never> {
        Just(companyModel).eraseToAnyPublisher()
    }
    var companyModel: CompanyModel?
}

final class MockFirebaseService: FirebaseServiceProtocol {
    func getImUser() -> Bool {
        return true
    }
    
    func getCurrentUserUid() -> String? {
        return "test_user_id"
    }
}

final class LeaguePresenterTests: XCTestCase {
    private var sut: LeaguePresenterImpl!
    private var mockUserDataUseCase: MockLeaguesUserDataUseCase!
    private var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        
        mockUserDataUseCase = MockLeaguesUserDataUseCase()
        let useCases = LeaguePresenterImpl.UseCases(
            userDataUseCase: mockUserDataUseCase,
            companyDataUseCase: MockCompanyDataUseCase()
        )
        
        let actions = LeaguePresenterImpl.Actions(
            goToCreateLeague: {},
            goToLeagueDetail: { _ in }
        )

        
        sut = LeaguePresenterImpl(
            useCases: useCases,
            actions: actions,
            firebaseService: MockFirebaseService()
        )
    }
    
    func test_viewDidLoad_showsNoLeaguesDialog_whenUserHasNoLeagues() {
        // Given
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let input = LeaguePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            deleteLeague: Empty().eraseToAnyPublisher(),
            openCreateLeague: Empty().eraseToAnyPublisher(),
            openLeagueDetail: Empty().eraseToAnyPublisher()
        )
        
        sut.transform(input: input)
        
        // When
        let user = UserModel(uid: "", fullname: "", username: "", email: "", misLigas: [:])
        viewDidLoadSubject.send(())
        mockUserDataUseCase.userInfoSubject.send(user)
        
        // Then
        let expectation = XCTestExpectation(description: "Espera cambio en el ViewModel")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.viewModel.loading)
            XCTAssertTrue(self.sut.viewModel.showNoLeaguesDialog)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_deleteLeague_removesLeagueFromViewModel() {
        // Given
        let testLeague = League(
            leagueId: "123",
            name: "Test League",
            drinks: 0,
            imageName: "copa1"
        )
        sut.viewModel.leaguesList = [testLeague]
        
        let deleteLeagueSubject = PassthroughSubject<League, Never>()
        let input = LeaguePresenterImpl.ViewInputs(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            deleteLeague: deleteLeagueSubject.eraseToAnyPublisher(),
            openCreateLeague: Empty().eraseToAnyPublisher(),
            openLeagueDetail: Empty().eraseToAnyPublisher()
        )
        
        sut.transform(input: input)
        
        // When
        deleteLeagueSubject.send(testLeague)
        
        // Then
        let expectation = XCTestExpectation(description: "Esperamos que la liga se elimine")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.viewModel.leaguesList.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}


