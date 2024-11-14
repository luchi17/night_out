import SwiftUI
import Combine

struct LoginView: View, Hashable {
    
    public let id = UUID()
    
    static func == (lhs: LoginView, rhs: LoginView) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Combina el id para el hash
    }
    
    @ObservedObject var viewModel: LoginViewModel
    let presenter: LoginPresenter
    
    private let loginPublisher = PassthroughSubject<Void, Never>()
    private let signupUserPublisher = PassthroughSubject<Void, Never>()
    private let signupCompanyPublisher = PassthroughSubject<Void, Never>()
    private let signupGooglePublisher = PassthroughSubject<Void, Never>()
    private let signupApplePublisher = PassthroughSubject<Void, Never>()
    
    @State private var showRegisterAlert = false  // Estado para mostrar la alerta
    
    init(
        presenter: LoginPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            // Background Image
            //            Image("imagen_inicio")
            //                .resizable()
            //                .edgesIgnoringSafeArea(.all)
            //                .aspectRatio(contentMode: .fill)
            
            VStack(spacing: 20) {
                // Logo
                Image("logo_amarillo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 162, height: 157)
                    .padding(.top, 90)
                
                // Email Input
                TextField("Email...", text: $viewModel.email)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2)) // Custom input background color
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                // Password Input
                SecureField("Password...", text: $viewModel.password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2)) // Custom input background color
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                // Login Button
                Button(action: {
                    loginPublisher.send()
                }) {
                    Text("Log in")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow) // Adjust as needed for your button style
                        .cornerRadius(25)
                        .shadow(radius: 4)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Apple Sign In Button
                appleLoginButton

                googleLoginButton
                
                Spacer()
                
                signupButton
                
            }
            .padding(.horizontal, 20)
        }
        .alert(isPresented: $showRegisterAlert) {
                        Alert(
                            title: Text("Selecciona una opción"),
                            message: Text("¿Cómo quieres registrarte?"),
                            primaryButton: .default(Text("Registrar Empresa"), action: {
                                showRegisterAlert.toggle()
                                signupCompanyPublisher.send()
                            }),
                            secondaryButton: .default(Text("Registrar Persona"), action: {
                                showRegisterAlert.toggle()
                                signupUserPublisher.send()
                            })
                        )
                    }
        .background(Color.green)
        .applyStates(
            error: (state: viewModel.headerError, onReload: { }),
            isIdle: viewModel.loading,
            showCloseButton: {
                //Resetting headerError
                self.viewModel.headerError = nil
            }
        )
        .navigationBarBackButtonHidden()
    }
    
    private var googleLoginButton: some View {
        Button(action: {
            signupGooglePublisher.send()
        }) {
            HStack {
                Image("google", bundle: .main)
                    .frame(width: 30, height: 30)
                    .scaledToFit()
                    .padding(.leading, 12)
                Text("Iniciar sesión con Google")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.black)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.5))
        }
        .cornerRadius(25)
    }
    
    private var signupButton: some View {
        Button(action: {
            showRegisterAlert.toggle()
        }) {
            Text("Need new account? Sign up")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple) // Adjust as needed for your button style
                .cornerRadius(25)
                .shadow(radius: 4)
        }
        .padding(.bottom, 40)
    }
    
    private var appleLoginButton: some View {
        Button(action: {
            signupApplePublisher.send()
        }) {
            Text("Iniciar sesión con Apple")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2)) // Adjust as needed
                .cornerRadius(25)
        }
        .padding(.top, 16)
    }
    
}

private extension LoginView {
    
    func bindViewModel() {
        let input = LoginPresenterImpl.ViewInputs(
            login: loginPublisher.eraseToAnyPublisher(),
            signupUser: signupUserPublisher.eraseToAnyPublisher(),
            signupCompany: signupCompanyPublisher.eraseToAnyPublisher(),
            signupWithGoogle: signupGooglePublisher.eraseToAnyPublisher(),
            signupWithApple: signupApplePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
