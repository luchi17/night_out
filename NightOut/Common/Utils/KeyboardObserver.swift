import SwiftUI
import Combine

class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    private var cancellables: Set<AnyCancellable> = []

    init() {
        // Observa la notificación de la aparición del teclado
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return 0
                }
                return keyboardFrame.height
            }
            .sink { [weak self] height in
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)

        // Observa la notificación de la desaparición del teclado
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .sink { [weak self] height in
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)
    }
}
//
//struct KeyboardAvoidingModifier: ViewModifier {
//    @State private var keyboardHeight: CGFloat = 0
//    @State private var cancellable: AnyCancellable?
//
//    func body(content: Content) -> some View {
//        content
//            .offset(y: -keyboardHeight / 2)
//            .onAppear {
//                cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
//                    .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
//                    .sink { notification in
//                        if notification.name == UIResponder.keyboardWillShowNotification,
//                           let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
//                            keyboardHeight = keyboardFrame.height
//                        } else {
//                            keyboardHeight = 0
//                        }
//                    }
//            }
//            .onDisappear {
//                cancellable?.cancel()
//            }
//    }
//}
//
//extension View {
//    func disableKeyboardAvoiding() -> some View {
//        self.modifier(KeyboardAvoidingModifier())
//    }
//}
