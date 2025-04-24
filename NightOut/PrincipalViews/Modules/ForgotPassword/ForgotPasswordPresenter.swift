import SwiftUI
import Combine
import FirebaseAuth


final class ForgotPasswordViewModel: ObservableObject {

    @Published var passwordToast: ToastType?
    @Published var loading: Bool = false
    
}


protocol ForgotPasswordPresenter {
    var viewModel: ForgotPasswordViewModel { get }
    func transform(input: ForgotPasswordPresenterImpl.ViewInputs)
}

final class ForgotPasswordPresenterImpl: ForgotPasswordPresenter {
    
    struct ViewInputs {
        let sendEmailForgotPwd: AnyPublisher<String, Never>
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    var viewModel: ForgotPasswordViewModel
    
    init() {
        viewModel = ForgotPasswordViewModel()
    }
    
    func transform(input: ForgotPasswordPresenterImpl.ViewInputs) {
        
        input
            .sendEmailForgotPwd
            .withUnretained(self)
            .sink { presenter, emailPwd in
                presenter.sendPasswordResetEmail(email: emailPwd)
            }
            .store(in: &cancellables)
    }
    
    private func sendPasswordResetEmail(email: String) {
        guard isValidEmail(email) else {
            self.viewModel.passwordToast = .custom(.init(title: "", description: " Por favor, ingresa un correo válido.", image: nil))
            return
        }
        
        viewModel.loading = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            self?.viewModel.loading = false
            if let error = error {
                self?.viewModel.passwordToast = .custom(.init(title: "Error", description: "Error al enviar correo \(error.localizedDescription).", image: nil))
                print("Error al enviar correo: \(error.localizedDescription)")
            } else {
                self?.viewModel.passwordToast = .success(.init(title: "", description: "Correo de restablecimiento enviado a \(email). Por favor revisa tu bandeja.", image: nil))
                print("Correo de restablecimiento enviado a \(email)")
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
        return emailPredicate.evaluate(with: email)
    }
}
