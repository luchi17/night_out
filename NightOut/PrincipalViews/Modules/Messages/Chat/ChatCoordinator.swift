
import SwiftUI
import Combine

class ChatCoordinator: ObservableObject, Hashable {
    
    let id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatCoordinator, rhs: ChatCoordinator) -> Bool {
        return lhs.id == rhs.id
    }
    
    private let actions: ChatPresenterImpl.Actions
    private let chat: Chat
    
    init(
        actions: ChatPresenterImpl.Actions,
        chat: Chat
    ) {
        self.actions = actions
        self.chat = chat
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = ChatPresenterImpl(
            useCases: .init(chatUseCase: ChatUseCaseImpl(repository: ChatRepositoryImpl.shared)),
            actions: actions,
            chat: chat
        )
        ChatView(presenter: presenter)
    }
}

