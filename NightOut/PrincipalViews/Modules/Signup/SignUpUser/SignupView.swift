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
        VStack(spacing: 10) {
            // Logo
            
            Spacer()
            
            Image("nightout")
                .resizable()
                .scaledToFit()
                .frame(height: 90)
                .foregroundStyle(.white)
            
            imagePicker
                .padding(.bottom, 20)
            
            TextField("", text: $viewModel.fullName, prompt: Text("Nombre...").foregroundColor(.white))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.all, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
                )
                .foregroundColor(.white)
                .accentColor(.white)
            
            TextField("", text: $viewModel.userName, prompt: Text("Usuario...").foregroundColor(.white))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.all, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
                )
                .foregroundColor(.white)
                .accentColor(.white)
            
            // Email Input
            TextField("", text: $viewModel.email, prompt: Text("Email...").foregroundColor(.white))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.all, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
                )
                .foregroundColor(.white)
                .accentColor(.white)
            
            // Password Input
            SecureField("", text: $viewModel.password, prompt: Text("Contraseña...").foregroundColor(.white))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.all, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
                )
                .foregroundColor(.white)
                .accentColor(.white)
                .padding(.bottom, 10)
            
            genderView
                .padding(.bottom, 10)
            
            TermsAndConditionsView(isAccepted: $termsAccepted)
                .padding(.bottom, 10)
            
            registerButton
            
            Spacer()
            
            alreadyHaveAnAccountButton
            
        }
        .padding(.horizontal, 20)
        .background(
            Color.black
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
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var genderView: some View {
        HStack {
            GenderCheckbox(gender: .male, selectedGender: $viewModel.gender)
            GenderCheckbox(gender: .female, selectedGender: $viewModel.gender)
            
            Spacer()
        }
    }
    
    private var imagePicker: some View {
        ImagePickerView(
            imageData: $viewModel.imageData,
            selectedImage: $viewModel.selectedImage
        ) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 2) // Borde blanco
                    .frame(width: 120, height: 120) // Tamaño del círculo
                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image("profile")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var registerButton: some View {
        Button(action: {
            signupPublisher.send()
        }) {
            Text("Registrarse")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(!termsAccepted ? Color.gray : Color.yellow)
                .cornerRadius(25)
        }
        .disabled(!termsAccepted)
        .padding(.bottom, 30)
    }
    
    private var alreadyHaveAnAccountButton: some View {
        Button(action: {
            loginPublisher.send()
        }) {
            Text("¿Tienes cuenta? Inicia Sesión")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 60)
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
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct GenderCheckbox: View {
    let gender: Gender
    @Binding var selectedGender: Gender?
    
    var body: some View {
        Button(action: {
            selectedGender = gender
        }) {
            HStack {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 2) // Círculo exterior
                        .frame(width: 24, height: 24)
                    
                    if selectedGender == gender {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20) // Círculo interno más pequeño para dejar padding
                    }
                }
                
                Text(gender.title)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .buttonStyle(PlainButtonStyle()) // Evita la animación del botón
    }
}
