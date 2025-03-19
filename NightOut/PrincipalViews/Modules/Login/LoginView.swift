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
    private let openForgotPasswordPublisher = PassthroughSubject<Void, Never>()
    
    @FocusState private var focusedField: Field?
    
    enum Field: Int, Hashable {
        case email, password
    }
    
    @State private var showRegisterAlert = false
    
    init(
        presenter: LoginPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            VStack(spacing: 0) {
                ScrollView {
                    ScrollViewReader { proxy in
                        
                        VStack {
                            Image("logo_amarillo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 162, height: 157)
                                .padding(.top, 90)
                            
                            // Email Input
                            TextField("", text: $viewModel.email, prompt: Text("Email...").foregroundColor(.yellow))
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.emailAddress)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.all, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10).stroke(Color.yellow, lineWidth: 1)
                                )
                                .foregroundColor(.yellow)
                                .accentColor(.yellow)
                                .padding(.bottom, 12)
                                .focused($focusedField, equals: .email)
                                .onSubmit {
                                    self.focusNextField($focusedField)
                                }
                            
                            
                            // Password Input
                            SecureField("",text: $viewModel.password, prompt: Text("Contraseña...").foregroundColor(.yellow))
                                .textContentType(.password)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.all, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10).stroke(Color.yellow, lineWidth: 1)
                                )
                                .foregroundColor(.yellow)
                                .accentColor(.yellow)
                                .padding(.bottom, 20)
                                .focused($focusedField, equals: .password)
                                .onSubmit {
                                    self.focusNextField($focusedField)
                                }
                            
                            // Login Button
                            Button(action: {
                                viewModel.loading = true
                                loginPublisher.send()
                            }) {
                                Text("Entrar".uppercased())
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.yellow)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.grayColor.opacity(0.5))
                                    .cornerRadius(25)
                                    .shadow(radius: 4)
                            }
                            .padding(.bottom, 12)
                            
                            googleLoginButton
                            
                            appleLoginButton
                            
                            forgotPasswordButton

                        }
                        .padding(.horizontal, 20)
                    }
                    
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
                
                Spacer()
                
            }
            
            VStack {
                Spacer()
                
                signupButton
            }
            .ignoresSafeArea(.keyboard)
            .padding(.horizontal, 20)
        }
        .background(
            Color.blackColor
        )
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: viewModel.loading,
            extraPadding: .none
        )
        .navigationBarBackButtonHidden()
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var googleLoginButton: some View {
        Button(action: {
            viewModel.loading = true
            signupGooglePublisher.send()
        }) {
            Text("Iniciar sesión con Google".uppercased())
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.yellow)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.grayColor.opacity(0.5))
                .cornerRadius(25)
                .shadow(radius: 4)
        }
    }
    
    private var forgotPasswordButton: some View {
        Button(action: {
            openForgotPasswordPublisher.send()
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
            signupUserPublisher.send()
        }) {
            Text("¿Cuenta nueva? Regístrate".uppercased())
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom)
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
                .background(Color.grayColor.opacity(0.5))
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
            openForgotPassword: openForgotPasswordPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
