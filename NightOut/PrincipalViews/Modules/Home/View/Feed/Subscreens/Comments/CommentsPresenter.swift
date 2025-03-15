import SwiftUI
import Combine

struct PostCommentsInfo {
    let postId: String
    let postImage: UIImage?
    let postIsFromUser: Bool
    let publisherId: String
    
}

final class CommentsViewModel: ObservableObject {
    @Published var postImage: UIImage?
    @Published var profileImage: String?
    @Published var commentText: String = ""
    @Published var comments: [UserCommentModel] = []
    @Published var toastError: ToastType?
    @Published var loading: Bool = false
    
    init(postImage: UIImage?, profileImage: String?) {
        self.postImage = postImage
        self.profileImage = profileImage
    }
}

protocol CommentsPresenter {
    var viewModel: CommentsViewModel { get }
    func transform(input: CommentsPresenterImpl.ViewInputs)
}

final class CommentsPresenterImpl: CommentsPresenter {
    
    struct UseCases {
        let postsUseCase: PostsUseCase
        let userDataUseCase: UserDataUseCase
        let companyDataUseCase: CompanyDataUseCase
        let notificationsUseCase: NotificationsUseCase
    }
    
    struct Actions {
        let goback: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let publishComment: AnyPublisher<Void, Never>
        let goback: AnyPublisher<Void, Never>
    }
    
    var viewModel: CommentsViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private let info: PostCommentsInfo
    
    init(
        useCases: UseCases,
        actions: Actions,
        info: PostCommentsInfo
    ) {
        self.actions = actions
        self.useCases = useCases
        self.info = info
        
        let profileImage = info.postIsFromUser ? UserDefaults.getUserModel()?.image : UserDefaults.getCompanyUserModel()?.imageUrl
        
        viewModel = CommentsViewModel(postImage: info.postImage, profileImage: profileImage)
    }
    
    func transform(input: CommentsPresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.postsUseCase.getComments(postId: presenter.info.postId)
                    .eraseToAnyPublisher()
            })
            .handleEvents(receiveRequest: { [weak self] _ in
                self?.viewModel.loading = true
            })
            .withUnretained(self)
            .flatMap({ presenter, commentsModel -> AnyPublisher<[UserCommentModel], Never> in
                presenter.transformModelsToUserModels(commentsModel: Array(commentsModel))
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
                    self.viewModel.toastError = .custom(.init(title: "Error", description: "No se han podido cargar los comentarios.", image: nil))
                }
            }, receiveValue: { presenter, comments in
                presenter.viewModel.loading = false
                presenter.viewModel.comments = comments
            })
            .store(in: &cancellables)
            

        input
            .publishComment
            .withUnretained(self)
            .filter( { $0.0.shouldPublishComment() })
            .flatMap({ presenter, _ -> AnyPublisher<UserCommentModel?, Never> in
                presenter.getAddedCommentModel()
            })
            .withUnretained(self)
            .sink { presenter, comment in
                if let comment = comment {
                    presenter.viewModel.toastError = nil
                    presenter.viewModel.commentText = ""
                    presenter.viewModel.comments.append(comment)
                
                    presenter.sendNotification(comment: comment)
                } else {
                    presenter.viewModel.toastError = .custom(.init(title: "Error", description: "Comentario no publicado.", image: nil))
                }
            }
            .store(in: &cancellables)
        
        input
            .goback
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goback()
            }
            .store(in: &cancellables)

    }
}

private extension CommentsPresenterImpl {
    func shouldPublishComment() -> Bool {
        if viewModel.commentText.isEmpty {
            viewModel.toastError = .custom(.init(title: "Por favor, primero escribe un comentario.", description: nil, image: nil))
            return false
        } else {
            viewModel.toastError = nil
            return true
        }
    }
    
    func sendNotification(comment: UserCommentModel) {
        guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid(),
                let commentText = comment.comment,
               info.publisherId != uid else {
            return
        }

        let model = NotificationModel(
            ispost: true,
            postid: info.postId,
            text: "\(comment.username ?? "") ha comentado: " + commentText,
            userid: uid
        )
        _ = self.useCases.notificationsUseCase.addNotification(model: model, publisherId: info.publisherId)
    }
    
    func getAddedCommentModel() -> AnyPublisher<UserCommentModel?, Never> {
        if let uid = FirebaseServiceImpl.shared.getCurrentUserUid() {
            let comment = CommentModel(
                comment: viewModel.commentText,
                publisher: uid
            )
            
            return useCases.postsUseCase.addComment(
                comment: comment,
                postId: info.postId
            )
            .withUnretained(self)
            .map { presenter, saved -> UserCommentModel? in
                guard saved else { return nil }
                
                let username: String = {
                    if FirebaseServiceImpl.shared.getImUser() {
                        return UserDefaults.getUserModel()?.username ?? "Desconocido"
                    } else {
                        return UserDefaults.getCompanyUserModel()?.username ?? "Desconocido"
                    }
                }()
                
                return UserCommentModel(
                    userImageUrl: presenter.viewModel.profileImage,
                    username: username,
                    comment: presenter.viewModel.commentText
                )
            }
            .eraseToAnyPublisher()
        } else {
            return Just(nil).eraseToAnyPublisher()
        }
    }
    
    func transformModelsToUserModels(commentsModel: [CommentModel]) -> AnyPublisher<[UserCommentModel], Never> {
        let publishers: [AnyPublisher<UserCommentModel, Never>] = commentsModel.map { comment in
            if UserDefaults.getCompanies()?.users.values.first(where: { $0.uid == comment.publisher }) != nil {
                return useCases.companyDataUseCase.getCompanyInfo(uid: comment.publisher)
                    .map { companyModel in
                        UserCommentModel(
                            userImageUrl: companyModel?.imageUrl,
                            username: companyModel?.username,
                            comment: comment.comment
                        )
                    }
                    .eraseToAnyPublisher()
            } else {
                return useCases.userDataUseCase.getUserInfo(uid: comment.publisher)
                    .map { userModel in
                        UserCommentModel(
                            userImageUrl: userModel?.image,
                            username: userModel?.username,
                            comment: comment.comment
                        )
                    }
                    .eraseToAnyPublisher()
            }
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
}
