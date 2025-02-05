import SwiftUI
import Combine

struct ChatView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let sendMessagePublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: ChatViewModel
    let presenter: ChatPresenter
    
    init(
        presenter: ChatPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.sender == viewModel.myUid {
                                    Spacer()
                                    Text(message.message)
                                        .padding(.all, 8)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                } else {
                                    Text(message.message)
                                        .padding(.all, 8)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            
            bottomView
            
        }
        .background(Color.black)
        .showCustomNavBar(
            title: viewModel.otherUsername,
            goBack: goBackPublisher.send
        )
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: viewModel.loading
        )
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    var bottomView: some View {
        HStack {
            TextField("Escribe un mensaje", text: $viewModel.newMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                sendMessagePublisher.send()
            }) {
                Image(systemName: "paperplane.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
}

private extension ChatView {
    func bindViewModel() {
        let input = ChatPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher(),
            sendMessage: sendMessagePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
