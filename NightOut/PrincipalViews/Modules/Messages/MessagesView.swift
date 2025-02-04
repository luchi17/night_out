import SwiftUI
import Combine

struct MessagesView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goToChatPublisher = PassthroughSubject<Chat, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: MessagesViewModel
    let presenter: MessagesPresenter
    
    init(
        presenter: MessagesPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
           if viewModel.chatList.isEmpty && !viewModel.loading {
                Spacer()
                Text("No has dado match con ningún usuario")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.chatList, id: \.id) { chat in
                            ChatRow(chat: chat)
                                .onTapGesture {
                                    goToChatPublisher.send(chat)
                                }
                        }
                    }
                    .background(Color.black)
                }
            }
        }
        .listStyle(PlainListStyle())
        .padding(.all, 12)
        .background(Color.black)
        .showCustomNavBar(
            title: "NIGHOUT MENSAJES",
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
        .background(Color.black.opacity(0.7))
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
}

private extension MessagesView {
    func bindViewModel() {
        let input = MessagesPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            goToChat: goToChatPublisher.eraseToAnyPublisher(),
            goBack: goBackPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}



// Modelo de datos para cada chat
class Chat: Identifiable {
    let id = UUID()
    let otherUserUid: String
    let username: String
    let lastMessage: String
    let profileImage: String?
    
    init(otherUserUid: String, username: String, lastMessage: String, profileImage: String?) {
        self.otherUserUid = otherUserUid
        self.username = username
        self.lastMessage = lastMessage
        self.profileImage = profileImage
    }
}

struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        HStack(spacing: 8) {
            if let userImageUrl = chat.profileImage {
                KingFisherImage(url: URL(string: userImageUrl))
                    .placeholder({
                        Image("profile")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    })
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
            
            VStack(spacing: 5) {
                
                Text(chat.username)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(chat.lastMessage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .background(Color.black)
    }
}
