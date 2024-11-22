import SwiftUI
import Combine

final class FeedViewModel: ObservableObject {
    
    @Published var posts: [PostModel] = []
    @Published var followModel: FollowModel?
    
    @Published var loading: Bool = false
    @Published var toastError: ToastType?
    
    private var matchingPosts: [PostsUser] = []
    
    init() {
        
    }
    
}

protocol FeedPresenter {
    var viewModel: FeedViewModel { get }
    func transform(input: FeedPresenterImpl.ViewInputs)
}

final class FeedPresenterImpl: FeedPresenter {
    
    struct UseCases {
        let postsUseCase: PostsUseCase
        let userDataUseCase: UserDataUseCase
        let companyDataUseCase: CompanyDataUseCase
    }
    
    struct Actions {
        //        let onOpenMaps: InputClosure<(Double, Double)>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
    }
    
    var viewModel: FeedViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = FeedViewModel()
    }
    
    func transform(input: FeedPresenterImpl.ViewInputs) {
        
        viewModel.loading = true
        
        let userPostsPublisher = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                presenter.useCases.postsUseCase.fetchFollow()
            })
            .withUnretained(self)
            .flatMap({ presenter, followModel -> AnyPublisher<[PostUserModel], Never> in
                presenter.useCases.postsUseCase.fetchPosts()
                    .map { posts in
                        let matchingPosts = posts.filter { post in
                            followModel?.following?.keys.contains(post.value.publisherId) ?? false
                        }
                        return Array(matchingPosts.values)
                    }
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .eraseToAnyPublisher()
        
        
        userPostsPublisher
            .flatMap({ presenter, userPosts ->  AnyPublisher<[PostModel], Never> in
                let publishers: [AnyPublisher<PostModel, Never>] = userPosts.map { post in
                    
                    if post.isFromUser ?? true {
                        presenter.getPostFromUserInfo(post: post)
                    } else {
                        presenter.getPostFromCompanyInfo(post: post)
                    }
                }
                
                return Publishers.MergeMany(publishers)
                    .collect()
                    .eraseToAnyPublisher()
            })
            .withUnretained(self)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished :
                    self.viewModel.loading = false
                case .failure(let error):
                    print("Error: \(error)")
                    self.viewModel.loading = false
                    self.viewModel.toastError = .custom(.init(title: "Error", description: "Could not load posts", image: nil))
                }
            }, receiveValue: { presenter, data in
                
                self.viewModel.loading = false
                
             presenter.viewModel.posts = data
                
            })
            .store(in: &cancellables)

    }
    
    private func getPostFromUserInfo(post: PostUserModel) -> AnyPublisher<PostModel, Never> {
        return self.useCases.userDataUseCase.getUserInfo(uid: post.publisherId)
            .map({ userInfo in
                return PostModel(
                    profileImageUrl: userInfo?.image,
                    postImage: post.postImage,
                    description: post.description,
                    location: post.location,
                    username: userInfo?.username,
                    uid: post.publisherId
                )
            })
            .eraseToAnyPublisher()
    }

    private func getPostFromCompanyInfo(post: PostUserModel) -> AnyPublisher<PostModel, Never> {
        self.useCases.companyDataUseCase.getCompanyInfo(uid: post.publisherId)
            .map({ companyInfo in
                return PostModel(
                    profileImageUrl: companyInfo?.imageUrl,
                    postImage: post.postImage,
                    description: post.description,
                    location: post.location,
                    username: companyInfo?.username,
                    uid: post.publisherId
                )
            })
            .eraseToAnyPublisher()
    }
}
