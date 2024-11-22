import SwiftUI
import Combine

struct FeedView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    
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
            VStack(spacing: 20) {
                ForEach(viewModel.posts, id: \.self) { post in
                    PostView(model: post)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 20)
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
}



private extension FeedView {
    
    func bindViewModel() {
        let input = FeedPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
