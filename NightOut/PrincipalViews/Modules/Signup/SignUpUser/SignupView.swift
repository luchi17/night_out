import SwiftUI
import Combine

struct SignupView: View {
    
    @ObservedObject var viewModel: SignupViewModel
    @State private var termsAccepted: Bool = false
    
    let presenter: SignupPresenter
    
    private let signupPublisher = PassthroughSubject<Void, Never>()
    private let loginPublisher = PassthroughSubject<Void, Never>()
    
    init(
        presenter: SignupPresenter
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
                
                TextField("Full Name...", text: $viewModel.fullName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2)) // Custom input background color
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
                // Password Input
                TextField("User Name...", text: $viewModel.userName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color.white.opacity(0.2)) // Custom input background color
                    .foregroundColor(.white)
                    .cornerRadius(10)
                
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
                
                TermsAndConditionsView(isAccepted: $termsAccepted)
                
                Spacer()
                
                registerButton
                
                Spacer()
                
                alreadyHaveAnAccountButton
                
            }
            .padding(.horizontal, 20)
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
    
    private var registerButton: some View {
        Button(action: {
            signupPublisher.send()
        }) {
            Text("Register")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(!termsAccepted ? Color.gray : Color.yellow)
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(radius: 4)
        }
        .disabled(!termsAccepted)
        .padding(.bottom, 40)
        
    }
    
    private var alreadyHaveAnAccountButton: some View {
        Button(action: {
            loginPublisher.send()
        }) {
            Text("Already have an account account? Sign in")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(25)
                .shadow(radius: 4)
        }
        .padding(.bottom, 100)
    }
    
}

private extension SignupView {
    
    func bindViewModel() {
        let input = SignupPresenterImpl.ViewInputs(
            signup: signupPublisher.eraseToAnyPublisher(),
            login: loginPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
