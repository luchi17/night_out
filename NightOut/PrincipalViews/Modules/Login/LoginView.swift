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
    private let signupPublisher = PassthroughSubject<Void, Never>()
    
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
                
                // Google Sign In Button
                Button(action: {
                    // Action for Google Sign In
                }) {
                    Text("Iniciar sesión con Google")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.yellow)
                        .frame(width: 340)
                        .padding()
                        .background(Color.gray.opacity(0.2)) // Adjust as needed
                        .cornerRadius(25)
                }
                .padding(.top, 16)
                
                Spacer()
                    
                // Sign Up Button
                Button(action: {
                    signupPublisher.send()
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
                .padding(.bottom, 20)
            }
            .padding([.leading, .trailing], 20)
        }
        .background(Color.orange)
        .applyStates(
            error: (state: viewModel.headerError, onReload: { }),
            isIdle: viewModel.loading
        )
    }
}

private extension LoginView {
    
    func bindViewModel() {
        let input = LoginPresenterImpl.ViewInputs(
            login: loginPublisher.eraseToAnyPublisher(),
            signup: signupPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
