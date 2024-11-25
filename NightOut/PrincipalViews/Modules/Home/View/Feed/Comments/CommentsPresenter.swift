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
                presenter.transformModelToUserModel(commentsModel: Array(commentsModel))
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
            .flatMap({ presenter, _ -> AnyPublisher<Bool, Never> in
                if let uid = FirebaseServiceImpl.shared.getCurrentUserUid() {
                    let comment = CommentModel(
                        comment: presenter.viewModel.commentText,
                        publisher: uid
                    )
                    return presenter.useCases.postsUseCase.addComment(
                        comment: comment,
                        postId: presenter.info.postId
                    )
                } else {
                    return Just(false)
                        .eraseToAnyPublisher()
                }
            })
            .withUnretained(self)
            .sink { presenter, saved in
                
                //añadir comment, llamar a srvicio? o añadir directamente a viewModel
//                self.viewModel.comments.append(<#T##newElement: UserCommentModel##UserCommentModel#>)
//                print(saved)
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
    
    func transformModelToUserModel(commentsModel: [CommentModel]) -> AnyPublisher<[UserCommentModel], Never> {
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

//private fun addComment() {
//      val commentsRef = FirebaseDatabase.getInstance().reference
//          .child("Comments")
//          .child(postId)
//      val commentsMap = HashMap<String, Any>()
//      commentsMap["comment"] = binding.addComment.text.toString()
//      commentsMap["publisher"] = firebaseUser!!.uid
//      commentsRef.push().setValue(commentsMap)
//      addNotification()
//      binding.addComment.text.clear()
//  }

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
