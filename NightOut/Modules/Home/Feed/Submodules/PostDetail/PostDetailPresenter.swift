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
        let goBack: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let openComments: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
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
        
        input
            .goBack
            .withUnretained(self)
            .sink { presenter, post in
                presenter.actions.goBack()
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
