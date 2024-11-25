import SwiftUI
import Combine

struct FeedView: View {
    
    @State private var showNavigationAlert = false
    @State private var postSelectedToNavigate: PostModel?
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let openMapsPublisher = PassthroughSubject<PostModel, Never>()
    private let openAppleMapsPublisher = PassthroughSubject<PostModel, Never>()
    private let showUserProfilePublisher = PassthroughSubject<PostModel, Never>()
    private let showPostCommentsPublisher = PassthroughSubject<PostModel, Never>()
    
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
                            openMaps: { postSelectedToNavigate in
                                self.postSelectedToNavigate = postSelectedToNavigate
                                showNavigationAlert = true
                            },
                            showUserOrCompanyProfile: {
                                showUserProfilePublisher.send(post)
                            },
                            showPostComments: {
                                showPostCommentsPublisher.send(post)
                            }
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
        .alert("Open Location", isPresented: $showNavigationAlert) {
            Button("Apple Maps") {
                if let postSelectedToNavigate = postSelectedToNavigate {
                    openAppleMapsPublisher.send(postSelectedToNavigate)
                    showNavigationAlert = false
                }
            }
            Button("Google Maps") {
                if let postSelectedToNavigate = postSelectedToNavigate {
                    openMapsPublisher.send(postSelectedToNavigate)
                    showNavigationAlert = false
                }
            }
            Button("Close", role: .cancel) {
                showNavigationAlert = false
            }
        } message: {
            Text("Choose an app to open the location.")
        }
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
            openAppleMaps: openAppleMapsPublisher.eraseToAnyPublisher(),
            showUserOrCompanyProfile: showUserProfilePublisher.eraseToAnyPublisher(),
            showCommentsView: showPostCommentsPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
