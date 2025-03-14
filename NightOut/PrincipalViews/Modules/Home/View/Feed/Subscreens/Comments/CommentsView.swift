import SwiftUI
import Combine

struct CommentsView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let publishCommentPublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
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
                        .padding(.vertical)
                    
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
                .padding(.bottom)
            
        }
        .padding(.horizontal, 20)
        .background(Color.blackColor.ignoresSafeArea())
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
        .showCustomNavBar(
            title: "Comentarios",
            goBack: goBackPublisher.send
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
            CircleImage(
                imageUrl: viewModel.profileImage,
                size: 40,
                border: false
            )
            .padding(.leading, 5)
            
            TextField("", text: $viewModel.commentText, prompt: Text("Escriba aquí ...").foregroundColor(Color.white.opacity(0.6)))
                .padding(10)
                .background(Color.grayColor.opacity(0.2))
                .cornerRadius(10)
                .foregroundColor(.white)
                .accentColor(Color.white)
            
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
            publishComment: publishCommentPublisher.eraseToAnyPublisher(),
            goback: goBackPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
