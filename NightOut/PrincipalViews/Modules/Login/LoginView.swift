import SwiftUI
import Combine

struct LoginView: View, Hashable {
    
    public let id = UUID()
    
    static func == (lhs: LoginView, rhs: LoginView) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @ObservedObject var viewModel: LoginViewModel
    let presenter: LoginPresenter
    
    private let loginPublisher = PassthroughSubject<Void, Never>()
    private let signupUserPublisher = PassthroughSubject<Void, Never>()
    private let signupCompanyPublisher = PassthroughSubject<Void, Never>()
    private let signupGooglePublisher = PassthroughSubject<Void, Never>()
    private let signupApplePublisher = PassthroughSubject<Void, Never>()
    private let sendEmailPasswordPublisher = PassthroughSubject<String, Never>()
    
    
    @State private var showRegisterAlert = false
    
    init(
        presenter: LoginPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            Image("logo_amarillo")
                .resizable()
                .scaledToFit()
                .frame(width: 162, height: 157)
                .padding(.top, 90)
            
            // Email Input
            TextField("", text: $viewModel.email, prompt: Text("Email...").foregroundColor(.yellow))
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color.clear)
                .foregroundColor(.yellow)
                .accentColor(.yellow)
                .cornerRadius(10)
                .padding(.bottom, 12)
            
            // Password Input
            SecureField("",text: $viewModel.password, prompt: Text("Password...").foregroundColor(.yellow))
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color.clear)
                .foregroundColor(.yellow)
                .accentColor(.yellow)
                .cornerRadius(10)
                .padding(.bottom, 20)
            
            // Login Button
            Button(action: {
                loginPublisher.send()
            }) {
                Text("Entrar".uppercased())
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(25)
                    .shadow(radius: 4)
            }
            .padding(.bottom, 12)
            
            googleLoginButton
            
            appleLoginButton
            
            forgotPasswordButton

            Spacer()
            
            signupButton
            
        }
        .padding(.horizontal, 20)
        .background(
            Color.black
        )
        .alert(isPresented: $showRegisterAlert) {
            Alert(
                title: Text("Selecciona una opción"),
                message: Text("¿Cómo quieres registrarte?"),
                primaryButton: .default(Text("Registrar Empresa"), action: {
                    showRegisterAlert = false
                    signupCompanyPublisher.send()
                }),
                secondaryButton: .default(Text("Registrar Persona"), action: {
                    showRegisterAlert = false
                    signupUserPublisher.send()
                })
            )
        }
        .sheet(isPresented: $viewModel.showForgotPwdView) {
            ForgotPasswordView(
                sendEmailPassword: sendEmailPasswordPublisher.send
            )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
//        .onAppear {
//            viewModel.email = ""
//            viewModel.password = ""
//        }
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: viewModel.loading,
            extraPadding: .small
        )
        .navigationBarBackButtonHidden()
    }
    
    private var googleLoginButton: some View {
        Button(action: {
            signupGooglePublisher.send()
        }) {
            Text("Iniciar sesión con Google".uppercased())
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.yellow)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.5))
                .cornerRadius(25)
                .shadow(radius: 4)
        }
        .cornerRadius(25)
    }
    
    private var forgotPasswordButton: some View {
        Button(action: {
            viewModel.showForgotPwdView.toggle()
        }) {
            HStack {
                Text("¿Olvidaste tu contraseña?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 12)
        }
    }
    
    private var signupButton: some View {
        Button(action: {
            showRegisterAlert = true
        }) {
            Text("¿Cuenta nueva? Regístrate".uppercased())
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 50)
    }
    
    private var appleLoginButton: some View {
        Button(action: {
            signupApplePublisher.send()
        }) {
            Text("Iniciar sesión con Apple")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.5))
                .cornerRadius(25)
        }
        .padding(.top, 12)
    }
    
}

private extension LoginView {
    
    func bindViewModel() {
        let input = LoginPresenterImpl.ViewInputs(
            login: loginPublisher.eraseToAnyPublisher(),
            signupUser: signupUserPublisher.eraseToAnyPublisher(),
            signupCompany: signupCompanyPublisher.eraseToAnyPublisher(),
            signupWithGoogle: signupGooglePublisher.eraseToAnyPublisher(),
            signupWithApple: signupApplePublisher.eraseToAnyPublisher(),
            sendEmailForgotPwd: sendEmailPasswordPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
