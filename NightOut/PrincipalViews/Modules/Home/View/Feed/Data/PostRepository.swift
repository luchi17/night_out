import Combine
import Foundation

protocol PostsRepository {
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never>
    func fetchFollow() -> AnyPublisher<FollowModel?, Never>
}

struct PostsRepositoryImpl: PostsRepository {
    
    static let shared: PostsRepository = PostsRepositoryImpl()

    private let network: PostDatasource

    init(
        network: PostDatasource = PostDatasourceImpl()
    ) {
        self.network = network
    }
    
    func fetchPosts() -> AnyPublisher<[String: PostUserModel], Never> {
        network
            .fetchPosts()
            .eraseToAnyPublisher()
    }
    
    func fetchFollow() -> AnyPublisher<FollowModel?, Never> {
        network
            .fetchFollow()
            .eraseToAnyPublisher()
    }
}
