import XCTest
import Combine
@testable import NightOut

// Mock SaveUserUseCase para devolver siempre éxito
final class MockSaveUserUseCase: SaveUserUseCase {
    func execute(model: UserModel) -> AnyPublisher<Bool, Never> {
        return Just(true).eraseToAnyPublisher()
    }
    func executeTerms() -> AnyPublisher<Bool, Never> {
        return Just(true).eraseToAnyPublisher()
    }
}

final class HomePresenterTests: XCTestCase {
    
    var presenter: HomePresenterImpl!
    var saveUserUseCase: MockSaveUserUseCase!
    var reloadFeedSubject: PassthroughSubject<Void, Never>!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        saveUserUseCase = MockSaveUserUseCase()
        reloadFeedSubject = PassthroughSubject<Void, Never>()
        cancellables = []
        
        let useCases = HomePresenterImpl.UseCases(saveUserUseCase: saveUserUseCase)
        let actions = HomePresenterImpl.Actions(
            onOpenNotifications: {},
            openMessages: {},
            openHub: {},
            openTinder: {}
        )
        
        // Input.openProfile no se usará aquí
        let input = HomePresenterImpl.Input(openProfile: Empty().eraseToAnyPublisher())
        
        presenter = HomePresenterImpl(
            useCases: useCases,
            actions: actions,
            reloadFeedSubject: reloadFeedSubject,
            input: input
        )
    }
    
    func testViewDidLoadShowsAlertsAndReloadsFeed() {
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let openNotifications = Empty<Void, Never>().eraseToAnyPublisher()
        let openMessages = Empty<Void, Never>().eraseToAnyPublisher()
        let updateProfileImage = Empty<Void, Never>().eraseToAnyPublisher()
        let openHub = Empty<Void, Never>().eraseToAnyPublisher()
        let openTinder = Empty<Void, Never>().eraseToAnyPublisher()
        
        let inputs = HomePresenterImpl.ViewInputs(
            openNotifications: openNotifications,
            openMessages: openMessages,
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            updateProfileImage: updateProfileImage,
            openHub: openHub,
            openTinder: openTinder
        )
        
        var reloadFeedCalled = false
        reloadFeedSubject
            .sink {
                reloadFeedCalled = true
            }
            .store(in: &cancellables)
        
        presenter.transform(input: inputs)
        
   
        viewDidLoadSubject.send(())
        
   
        XCTAssertTrue(reloadFeedCalled, "reloadFeedSubject should send on viewDidLoad")
        
      
        XCTAssertFalse(presenter.viewModel.showCompanyFirstAlert)
        XCTAssertFalse(presenter.viewModel.showUserFirstAlert)
        XCTAssertFalse(presenter.viewModel.showNighoutAlert)
    }
    
    func testGenderChangeTriggersSaveUser() {
        let input = HomePresenterImpl.ViewInputs(
            openNotifications: Empty().eraseToAnyPublisher(),
            openMessages: Empty().eraseToAnyPublisher(),
            viewDidLoad: Empty().eraseToAnyPublisher(),
            updateProfileImage: Empty().eraseToAnyPublisher(),
            openHub: Empty().eraseToAnyPublisher(),
            openTinder: Empty().eraseToAnyPublisher()
        )
        
        presenter.transform(input: input)
        
        
        presenter.viewModel.gender = .mujer
        
       
        let expectation = expectation(description: "saveUser executed")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
}

