import SwiftUI
import Combine
import Kingfisher

struct CommentsView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let publishCommentPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: CommentsViewModel
    let presenter: CommentsPresenter
    
    init(
        presenter: CommentsPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            topView
            
            Spacer()
                .background(Color.black.opacity(0.9))
            
            // Lista de comentarios invertida
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.comments.reversed(), id: \.uid) { commentModel in
                        CommentView(commentModel: commentModel)
                            .scaleEffect(y: -1) // Invierte cada fila
                    }
                }
                .scaleEffect(y: -1) // Invierte el contenedor
                .padding()
            }

            bottomView
        }
        .background(Color.black.opacity(0.9))
        .showToast(
            error: (
                type: viewModel.toastError,
                showCloseButton: false,
                onDismiss: { }
            ),
            isIdle: viewModel.loading
        )
        .onAppear {
            viewDidLoadPublisher.send()
        }
        .onTapGesture {
             hideKeyboard()
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var topView: some View {
        VStack(spacing: 0) {
            Text("Comentarios")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.black))
            
            if let postImage = viewModel.postImage {
                KingFisherImage(url: URL(string: postImage))
                    .centerCropped(width: .infinity, height: 300, placeholder: {
                        ZStack {
                            Color.gray
                            ProgressView()
                        }
                    })
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .clipped()
            }
        }
    }
    
    var bottomView: some View {
        HStack {
            if let profileImage = viewModel.profileImage {
                KingFisherImage(url: URL(string: profileImage))
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.leading, 5)
                
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.leading, 5)
            }
            
            TextField("Escriba aquí ...", text: $viewModel.commentText)
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
            
            Button(action: {
                publishCommentPublisher.send()
                hideKeyboard()
            }) {
                Text("Publicar")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 40)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .padding(.trailing, 10)
        }
        .padding(.vertical, 10)
    }
}


private extension CommentsView {
    func bindViewModel() {
        let input = CommentsPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            publishComment: publishCommentPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
