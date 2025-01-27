import SwiftUI
import Combine



final class PostDetailViewModel: ObservableObject {
    @Published var post: NotificationModelForView
    @Published var postImage: UIImage?
    
    init(post: NotificationModelForView) {
        self.post = post
    }
}

protocol PostDetailPresenter {
    var viewModel: PostDetailViewModel { get }
    func transform(input: PostDetailPresenterImpl.ViewInputs)
}

final class PostDetailPresenterImpl: PostDetailPresenter {
    
    struct UseCases {
    }
    
    struct Actions {
        let openComments: InputClosure<PostCommentsInfo>
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let openComments: AnyPublisher<Void, Never>
    }
    
    var viewModel: PostDetailViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private let post: NotificationModelForView
    
    init(
        useCases: UseCases,
        actions: Actions,
        post: NotificationModelForView
    ) {
        self.actions = actions
        self.useCases = useCases
        self.post = post

        viewModel = PostDetailViewModel(post: post)
    }
    
    func transform(input: PostDetailPresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .flatMapLatest({ presenter, _ in
                presenter.getPostImagePublisher(image: presenter.post.postImage)
            })
            .withUnretained(self)
            .sink { presenter, postImage in
                presenter.viewModel.postImage = postImage
            }
            .store(in: &cancellables)
//            .performRequest(request: { presenter, _ -> AnyPublisher<PostUserModel?, Never> in
//                presenter.useCases.postsUseCase
//                    .fetchPosts()
//                    .map({ posts in
//                        let matchingPost = posts.first(where: { $0.value.postID == presenter.postId })?.value
//                        
//                        return matchingPost
//                    })
//                    .eraseToAnyPublisher()
//            }, loadingClosure: { [weak self] loading in
//                guard let self = self else { return }
//                self.viewModel.loading = loading
//            }, onError: { _ in })
//            .withUnretained(self)
//            .flatMap({ presenter, post -> AnyPublisher<(PostDetailModel?, PostUserModel?), Never> in
//                guard let publisherId = post?.publisherId else {
//                    return Just((nil, post)).eraseToAnyPublisher()
//                }
//                if post?.isFromUser ?? true {
//                    return presenter.useCases.userDataUseCase.getUserInfo(uid: publisherId)
//                        .map({ userModel in
//                            (
//                                PostDetailModel(
//                                userImage: userModel?.image,
//                                username: userModel?.username,
//                                fullname: userModel?.fullname
//                            )
//                                ,
//                                post
//                            )
//                        })
//                        .eraseToAnyPublisher()
//                } else {
//                    return presenter.useCases.companyDataUseCase.getCompanyInfo(uid: publisherId)
//                        .map({ userModel in
//                            (
//                                PostDetailModel(
//                                userImage: userModel?.imageUrl,
//                                username: userModel?.username,
//                                fullname: userModel?.fullname
//                            ),
//                            
//                                post
//                            )
//                        })
//                        .eraseToAnyPublisher()
//                }
//            })
//            .withUnretained(self)
//            .sink { presenter, data in
//                let matchingPost = data.1
//                presenter.viewModel.post = data.1
//                presenter.viewModel.username = data.0?.username ?? "Nombre"
//                presenter.viewModel.fullName = data.0?.fullname ?? "Nombre Completo"
//                presenter.viewModel.userProfileImage = data.0?.userImage
//            }
//            .store(in: &cancellables)
//        
//        
        input
            .openComments
            .withUnretained(self)
            .sink { presenter, _ in
                let info = PostCommentsInfo(
                    postId: presenter.post.postId,
                    postImage: presenter.viewModel.postImage,
                    postIsFromUser: !presenter.post.isFromCompany,
                    publisherId: presenter.post.userId
                )
                
                
                presenter.actions.openComments(info)
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
