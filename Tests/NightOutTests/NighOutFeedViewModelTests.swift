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
        // Creamos algunos datos de ejemplo para cambiar los posts
        let postModel = PostModel(
            profileImageUrl: "https://example.com/image.jpg",
            postImage: UIImage(),
            description: "Post de ejemplo",
            location: "Ubicación",
            username: "Usuario",
            fullName: "Nombre Completo",
            uid: "123",
            isFromUser: true,
            publisherId: "user123",
            timestamp: 123456789
        )
        
        // Simulamos un cambio en la lista de posts
        viewModel.posts = [postModel]
        
        // Comprobamos que la lista de posts se actualiza correctamente
        XCTAssertEqual(viewModel.posts.count, 1)
        XCTAssertEqual(viewModel.posts.first?.description, "Post de ejemplo")
    }

    func testLoadingState() {
        // Verificamos que el estado de carga se actualiza correctamente
        viewModel.loading = true
        XCTAssertEqual(viewModel.loading, true)
        
        viewModel.loading = false
        XCTAssertEqual(viewModel.loading, false)
    }
    
    func testFollowersCount() {
        // Verificamos el cambio en el número de seguidores
        viewModel.followersCount = 100
        XCTAssertEqual(viewModel.followersCount, 100)
    }
}

