import SwiftUI
import Combine

struct PostDetailView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let openCommentsPubliser = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: PostDetailViewModel
    let presenter: PostDetailPresenter
    
    init(
        presenter: PostDetailPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            VStack(alignment: .leading, spacing: 20) {
                
                userView
                    .padding(.top, 25)
                
                postView
                
                Button(action: {
                    openCommentsPubliser.send()
                }) {
                    Text("Ver comentarios")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(alignment: .leading)
                }
                Spacer()
            }
            .padding([.leading, .trailing], 20)
            
        }
        .background(
            Color.blackColor
                .edgesIgnoringSafeArea(.all)
        )
        .showCustomNavBar(
            title: "Post",
            goBack: goBackPublisher.send
        )
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    var postView: some View {
        VStack(spacing: 10) {
            if let postImage = viewModel.post.postImage {
                KingFisherImage(url: URL(string: postImage))
                    .placeholder({
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 300)
                            .clipped()
                    })
                    .scaledToFill()
                    .clipped()

            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .clipped()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 0) {
                Text(viewModel.post.text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.top, 5)
                
                Spacer()
            }
            
        }
    }
    
    var userView: some View {
        HStack(spacing: 8) {
            CircleImage(
                imageUrl: viewModel.post.profileImage,
                size: 50,
                border: true
            )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.post.userName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text(viewModel.post.fullName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
    }
}

private extension PostDetailView {
    func bindViewModel() {
        let input = PostDetailPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            openComments: openCommentsPubliser.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
