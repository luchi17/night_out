import SwiftUI
import Combine
import Foundation

struct ChatView: View {
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let sendMessagePublisher = PassthroughSubject<Void, Never>()
    private let goBackPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
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
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.sender == viewModel.myUid
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .animation(.easeOut(duration: 0.2), value: keyboardObserver.keyboardHeight + 50) // Suaviza la animación del teclado
                    .onChange(of: viewModel.messages.count) {
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                        
                    }
                }
                .onChange(of: keyboardObserver.keyboardHeight) {
                    // Cuando el teclado aparece o desaparece, desplazamos la vista
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                   }
                }
            }
            
            bottomView
            
        }
        .background(Color.blackColor)
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
        .onTapGesture {
            // Cerrar el teclado cuando tocas fuera de él
            hideKeyboard()
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
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct MessageBubble: View {
    let message: MessageModel
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            Text(message.message)
                .padding(.all, 8)
                .background(isFromCurrentUser ? Color.blue : Color.white)
                .foregroundColor(isFromCurrentUser ? Color.white : Color.blackColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            if !isFromCurrentUser { Spacer() }
        }
    }
}
