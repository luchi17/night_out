import SwiftUI
import Combine

#warning("TODO: show company register")
struct SignupCompanyView: View {
    
    @ObservedObject var viewModel: SignupCompanyViewModel
    
    let presenter: SignupCompanyPresenter
    
    private let signupCompanyPublisher = PassthroughSubject<Void, Never>()
    private let loginPublisher = PassthroughSubject<Void, Never>()
    
    init(
        presenter: SignupCompanyPresenter
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
            
            VStack(spacing: 10) {
                // Logo
                
                Spacer()
                
                selectPhotoButton
                
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
                
                locationButton
                startTimeButton
                endTimeButton
                selectTag
                
               
                Spacer()
                
                HStack(spacing: 20) {
                    registerButton
                    Spacer()
                    signInButton
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.gray)
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
            signupCompanyPublisher.send()
        }) {
            Text("Register")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(radius: 4)
        }
        
    }
    
    private var signInButton: some View {
        Button(action: {
            loginPublisher.send()
        }) {
            Text("Sign in")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(radius: 4)
        }
    }
    
    private var selectPhotoButton: some View {
        Button(action: {
            
        }) {
            Text("SELECT PROFILE PHOTO")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .shadow(radius: 4)
        }
        .padding(.bottom, 10)
    }
    
    private var locationButton: some View {
        Button(action: {
            
        }) {
            Text("LOCATION")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .shadow(radius: 4)
        }
    }
    
    private var startTimeButton: some View {
        Button(action: {
            
        }) {
            Text("START TIME")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .shadow(radius: 4)
        }
    }
    
    private var endTimeButton: some View {
        Button(action: {
            
        }) {
            Text("END TIME")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .shadow(radius: 4)
        }
    }
    
    private var selectTag: some View {
        Button(action: {
            
        }) {
            Text("SELECT TAG")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .shadow(radius: 4)
        }
    }
    
}

private extension SignupCompanyView {
    
    func bindViewModel() {
        let input = SignupCompanyPresenterImpl.ViewInputs(
            signupCompany: signupCompanyPublisher.eraseToAnyPublisher(),
            login: loginPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
