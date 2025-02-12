import SwiftUI
import Combine

struct UserPostProfileInfo {
    var profileId: String
    var profileImageUrl: String?
    var username: String
    var fullName: String
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

final class UserPostProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = "Nombre no disponible"
    @Published var fullname: String = "Username no disponible"
    @Published var followersCount: String = "0"
    @Published var discosCount: String = "0"
    @Published var copasCount: String = "0"
    @Published var images: [IdentifiableImage] = []

    init(profileImageUrl: String? = nil, username: String, fullname: String, discosCount: String, copasCount: String) {
        self.profileImageUrl = profileImageUrl
        self.username = username
        self.fullname = fullname
        self.discosCount = discosCount
        self.copasCount = copasCount
    }
}

protocol UserPostProfilePresenter {
    var viewModel: UserPostProfileViewModel { get }
    func transform(input: UserPostProfilePresenterImpl.ViewInputs)
}

final class UserPostProfilePresenterImpl: UserPostProfilePresenter {
    
    struct UseCases {
        let followUseCase: FollowUseCase
        let postsUseCase: PostsUseCase
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
    }
    
    var viewModel: UserPostProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private let info: UserPostProfileInfo
    
    init(
        useCases: UseCases,
        actions: Actions,
        info: UserPostProfileInfo
    ) {
        self.actions = actions
        self.useCases = useCases
        self.info = info

        viewModel = UserPostProfileViewModel(
            profileImageUrl: info.profileImageUrl,
            username: info.username,
            fullname: info.fullName,
            discosCount: "0",
            copasCount: "0"
            
        )
    }
    
    func transform(input: UserPostProfilePresenterImpl.ViewInputs) {
        let postsPublisher = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.followUseCase.fetchFollow(id: presenter.info.profileId)
                    .handleEvents(receiveOutput: { [weak self] followModel in
                        self?.viewModel.followersCount = String(followModel?.followers?.count ?? 0)
                        
                    })
                    .eraseToAnyPublisher()
            })
            .filter({ _ in !FirebaseServiceImpl.shared.getImUser() })
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.postsUseCase.fetchPosts()
                    .map { posts in
                        let matchingPosts = posts.filter { post in
                            return post.value.publisherId == presenter.info.profileId
                        }.values
                        return Array(matchingPosts)
                    }
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
        
        postsPublisher
            .withUnretained(self)
            .flatMap { presenter, posts in
                let publishers: [AnyPublisher<IdentifiableImage, Never>] = posts.map { post in
                    
                    presenter.getPostImagePublisher(image: post.postImage)
                        .compactMap({ $0 })
                        .map({ IdentifiableImage(image: $0 )})
                        .eraseToAnyPublisher()
                }
                return Publishers.MergeMany(publishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink { presenter, images in
                presenter.viewModel.images = images
            }
            .store(in: &cancellables)

    }
    
    func getPostImagePublisher(image: String?) -> AnyPublisher<UIImage?, Never> {
        if let image = image, let url = URL(string: image) {
            return KingFisherImage.fetchImagePublisher(url: url)
        }
        
        return Just(nil).eraseToAnyPublisher()
    }
}
