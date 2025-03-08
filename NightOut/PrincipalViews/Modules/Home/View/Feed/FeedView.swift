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
    private let openCalendarPublisher = PassthroughSubject<Void, Never>()
    
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
            if viewModel.showDiscoverEvents {
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
        .scrollIndicators(.hidden)
        .padding(.horizontal, 20)
        .onAppear {
            viewDidLoadPublisher.send()
        }
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
        .alert("Abrir localización", isPresented: $showNavigationAlert) {
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
            Button("Cerrar", role: .cancel) {
                showNavigationAlert = false
            }
        } message: {
            Text("Elige una app para abrir la localización.")
        }
    }
    
    var noPostsView: some View {
        VStack(alignment: .center, spacing: 20) {
            
            Spacer()
            
            Image("descubrirEventos")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .foregroundColor(.white)
                .padding(.top, 100)
            
            Button(action: {
                openCalendarPublisher.send()
            }) {
                Text("Descubrir eventos".uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .padding(.all, 12)
                    .background(Color.grayColor)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private extension FeedView {
    
    func bindViewModel() {
        let input = FeedPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            openMaps: openMapsPublisher.eraseToAnyPublisher(),
            openAppleMaps: openAppleMapsPublisher.eraseToAnyPublisher(),
            showUserOrCompanyProfile: showUserProfilePublisher.eraseToAnyPublisher(),
            showCommentsView: showPostCommentsPublisher.eraseToAnyPublisher(),
            openCalendar: openCalendarPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
