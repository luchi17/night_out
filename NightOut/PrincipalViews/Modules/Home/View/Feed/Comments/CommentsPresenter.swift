import SwiftUI
import Combine

struct PostCommentsInfo {
    let postId: String
    let postImageUrl: String
    let postIsFromUser: Bool
    let publisherId: String
    
}

final class CommentsViewModel: ObservableObject {
    @Published var postImage: String?
    @Published var profileImage: String?
    @Published var commentText: String = ""
    @Published var comments: [UserCommentModel] = []
    @Published var toastError: ToastType?
    @Published var loading: Bool = false
    
    init(postImage: String?, profileImage: String?) {
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
    }
    
    struct Actions {
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let publishComment: AnyPublisher<Void, Never>
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
        
        viewModel = CommentsViewModel(postImage: info.postImageUrl, profileImage: profileImage)
    }
    
    func transform(input: CommentsPresenterImpl.ViewInputs) {
        input
            .viewDidLoad
            .withUnretained(self)
            .flatMap({ presenter, _ in
                presenter.useCases.postsUseCase.getComments(postId: presenter.info.postId)
                    .map({ Array($0.values) })
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
                    self.viewModel.toastError = .custom(.init(title: "Error", description: "Could not load comments", image: nil))
                }
            }, receiveValue: { presenter, comments in
                presenter.viewModel.comments = comments
            })
            .store(in: &cancellables)
            

        input
            .publishComment
            .withUnretained(self)
            .filter( { $0.0.publishComment() })
            .flatMap({ presenter, _ -> AnyPublisher<UserCommentModel?, Never> in
                presenter.getAddedCommentModel()
            })
            .withUnretained(self)
            .sink { presenter, comment in
                if let comment = comment {
                    presenter.viewModel.toastError = nil
                    presenter.viewModel.commentText = ""
                    presenter.viewModel.comments.append(comment)
                } else {
                    presenter.viewModel.toastError = .custom(.init(title: "Error", description: "Could not publish comment", image: nil))
                }
            }
            .store(in: &cancellables)

    }
}

private extension CommentsPresenterImpl {
    func publishComment() -> Bool {
        if viewModel.commentText.isEmpty {
            viewModel.toastError = .custom(.init(title: "Please write comment first", description: "", image: nil))
            return false
        } else {
            viewModel.toastError = nil
            return true
        }
    }
    
    func getAddedCommentModel() -> AnyPublisher<UserCommentModel?, Never> {
        if let uid = FirebaseServiceImpl.shared.getCurrentUserUid() {
            let comment = CommentModel(
                comment: viewModel.commentText,
                publisher: uid
            )
            //MANDAR String: String... miraar firebase, se guardan mal los coments
            return useCases.postsUseCase.addComment(
                comment: comment,
                postId: info.postId
            )
            .withUnretained(self)
            .map { presenter, saved -> UserCommentModel? in
                guard saved else { return nil }
                
                let username: String = {
                    if FirebaseServiceImpl.shared.getImUser() {
                        return UserDefaults.getUserModel()?.username ?? "Unknown"
                    } else {
                        return UserDefaults.getCompanyUserModel()?.username ?? "Unknown"
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

//private fun addNotification() {
//       val notiRef = FirebaseDatabase.getInstance()
//           .reference.child("Notifications").child(publisherId)
//       val notiMap = HashMap<String, Any>()
//       notiMap["userid"] = firebaseUser!!.uid
//       notiMap["text"] = "commented: " + binding.addComment.text.toString()
//       notiMap["postid"] = postId
//       notiMap["ispost"] = true
//
//       notiRef.push().setValue(notiMap)
//   }
#warning("ADD notification using publisherId")
