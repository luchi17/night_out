import SwiftUI
import Combine
import Kingfisher

struct CommentsView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let publishCommentPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
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
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    topView
                        .padding()
                    
                    if viewModel.comments.isEmpty {
                        Spacer()
                            .background(Color.blackColor)
                    }
                    
                    VStack(alignment: .leading) {
                        ForEach(viewModel.comments.reversed(), id: \.uid) { commentModel in
                            CommentView(commentModel: commentModel)
                                .scaleEffect(y: -1) // Invierte cada fila
                                .id(commentModel.uid)
                        }
                    }
                    .scaleEffect(y: -1) // Invierte el contenedor
                    .padding()
                    .animation(.easeOut(duration: 0.2), value: keyboardObserver.keyboardHeight + 50) // Suaviza la animación del teclado
                    .onChange(of: viewModel.comments.count) {
                        withAnimation {
                            proxy.scrollTo(viewModel.comments.last?.uid, anchor: .bottom)
                        }
                        
                    }
                }
                .onChange(of: keyboardObserver.keyboardHeight) {
                    // Cuando el teclado aparece o desaparece, desplazamos la vista
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            proxy.scrollTo(viewModel.comments.last?.uid, anchor: .bottom)
                        }
                    }
                }
            }
            
            bottomView
                .padding()
            
        }
        .background(Color.blackColor)
        .showToast(
            error: (
                type: viewModel.toastError,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toastError = nil
                }
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
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blackColor)
            
            if let postImage = viewModel.postImage {
                Image(uiImage: postImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .clipped()
            } else {
                Image("profile")
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
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.leading, 5)
            }
            
            TextField("Escriba aquí ...", text: $viewModel.commentText)
                .padding(10)
                .background(Color.grayColor.opacity(0.2))
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
                    .background(Color.blackColor)
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
