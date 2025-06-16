import XCTest
import Combine
@testable import NightOut


final class SearchPresenterTests: XCTestCase {
    var presenter: SearchPresenterImpl!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        
        // Mock UseCases y Actions, con closures vacíos para las acciones
        let useCases = SearchPresenterImpl.UseCases(followUseCase: FollowUseCaseMock())
        let actions = SearchPresenterImpl.Actions(
            goToProfile: { _ in },
            goToPrivateProfile: { _ in }
        )
        
        presenter = SearchPresenterImpl(useCases: useCases, actions: actions)
        
        // Mockeamos el método searchUsers para devolver siempre un perfil fijo
        presenter.searchUsersClosure = { query in
            let profile = ProfileModel(profileImageUrl: "", username: "testuser", fullname: "Test User", profileId: "123", isCompanyProfile: false, isPrivateProfile: false)
            return Just([profile]).eraseToAnyPublisher()
        }
    }
    
    func testSearchTextUpdatesSearchResults() {
        let expectation = self.expectation(description: "searchResults updated")
        
        presenter.transform(input: SearchPresenterImpl.ViewInputs(
               viewDidLoad: Empty().eraseToAnyPublisher(),
               search: Empty().eraseToAnyPublisher(),
               goToProfile: Empty().eraseToAnyPublisher()
           ))
           
        // Observar cambios en searchResults
        presenter.viewModel.$searchResults
            .dropFirst() // Ignorar valor inicial vacío
            .sink { results in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results.first?.username, "testuser")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulamos la entrada de texto para disparar la búsqueda
        DispatchQueue.main.async {
            self.presenter.viewModel.searchText = "test"
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}


private final class FollowUseCaseMock: FollowUseCase {
    
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
