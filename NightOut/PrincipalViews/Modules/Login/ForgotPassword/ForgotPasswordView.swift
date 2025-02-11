import SwiftUI
import Combine

struct ForgotPasswordView: View, Hashable {
    
    public let id = UUID()
    
    static func == (lhs: ForgotPasswordView, rhs: ForgotPasswordView) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @State var email: String = ""
    
    private let sendEmailPasswordPublisher = PassthroughSubject<String, Never>()
    
    @ObservedObject var viewModel: ForgotPasswordViewModel
    let presenter: ForgotPasswordPresenter
    
    init(
        presenter: ForgotPasswordPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        
        VStack {
            Text("Recuperar Contraseña".uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 40)
            
            Text("Introduce tu correo asociado para continuar.")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)
            
            TextField("", text: $email, prompt: Text("Correo asociado a su cuenta...").foregroundColor(.yellow))
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.yellow)
                .accentColor(.yellow)
                .cornerRadius(10)
                .padding(.top, 20)
            
            Button(action: {
                sendEmailPasswordPublisher.send(email)
            }) {
                Text("Enviar".uppercased())
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(25)
                    .shadow(radius: 4)
            }
            .padding(.top, 12)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(
            Color.black
        )
        .showToast(
            error: (
                type: viewModel.passwordToast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.passwordToast = nil
                }
            ),
            isIdle: viewModel.loading,
            extraPadding: .none
        )
    }
}

private extension ForgotPasswordView {
    
    func bindViewModel() {
        let input = ForgotPasswordPresenterImpl.ViewInputs(
            sendEmailForgotPwd: sendEmailPasswordPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
