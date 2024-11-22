import SwiftUI
import Combine

struct FeedView: View {
    
    @State private var showEmptyView = false
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let openMapsPublisher = PassthroughSubject<String, Never>()
    private let showUserProfilePublisher = PassthroughSubject<String, Never>()
    
    @ObservedObject var viewModel: FeedViewModel
    let presenter: FeedPresenter
    
    init(
        presenter: FeedPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
            ScrollView {
                if viewModel.posts.isEmpty && !viewModel.loading {
                    noPostsView
                } else {
                    VStack(spacing: 20) {
                        ForEach(viewModel.posts, id: \.self) { post in
                            PostView(
                                model: post,
                                openMaps: openMapsPublisher.send,
                                showUserProfile: showUserProfilePublisher.send
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color.blue)
            .scrollIndicators(.hidden)
            .padding(.horizontal, 20)
            .onAppear {
                viewDidLoadPublisher.send()
            }
            .showToast(
                error: (
                    type: viewModel.toastError,
                    showCloseButton: false,
                    onDismiss: { }
                ),
                isIdle: viewModel.loading
            )
    }
    
    var noPostsView: some View {
        EmptyView()
            .overlay(alignment: .center) {
                Button {
                    //TODO
                } label: {
                    Text("No sigues a nadie.\nCargar mensajes de ejemplo")
                        .foregroundStyle(.white)
                }
                .background(.yellow)
            }
    }
}



private extension FeedView {
    
    func bindViewModel() {
        let input = FeedPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            openMaps: openMapsPublisher.eraseToAnyPublisher(),
            showUserProfile: showUserProfilePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
