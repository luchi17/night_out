import XCTest
import Combine
@testable import NightOut

final class FeedViewModelTests: XCTestCase {

    var viewModel: FeedViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = FeedViewModel()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }
    
    func testChangePosts() {

    }

    func testLoadingState() {
 
    }
    
    func testFollowersCount() {
        // Verificamos el cambio en el número de seguidores

    }
}

