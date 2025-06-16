import SwiftUI
import Combine

struct SignupView: View {
    
    @ObservedObject var viewModel: SignupViewModel
    @State private var termsAccepted: Bool = false
    
    let presenter: SignupPresenter
    
    private let signupPublisher = PassthroughSubject<Void, Never>()
    private let loginPublisher = PassthroughSubject<Void, Never>()
    private let openPickerPublisher = PassthroughSubject<Void, Never>()
    
    @FocusState private var focusedField: Field?
    
    enum Field: Int, Hashable {
        case fullname, username, email, password
    }
    
    init(
        presenter: SignupPresenter
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
                        VStack(spacing: 10) {
                            
                            Spacer()
                            
                            Image("n_logo")
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
                                .focused($focusedField, equals: .fullname)
                                .onSubmit {
                                    self.focusNextField($focusedField)
                                }
                            
                            TextField("", text: $viewModel.userName, prompt: Text("Usuario...").foregroundColor(.white))
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .accentColor(.white)
                                .padding(.all, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
                                )
                                .focused($focusedField, equals: .username)
                                .onSubmit {
                                    self.focusNextField($focusedField)
                                }
                            
                            // Email Input
                            TextField("", text: $viewModel.email, prompt: Text("Email...").foregroundColor(.white))
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.all, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
                                )
                                .foregroundColor(.white)
                                .accentColor(.white)
                                .focused($focusedField, equals: .email)
                                .onSubmit {
                                    self.focusNextField($focusedField)
                                }
                            
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
                                .focused($focusedField, equals: .password)
                                .onSubmit {
                                    self.focusNextField($focusedField)
                                }
                            
                            genderView
                                .padding(.bottom, 10)
                            
                            TermsAndConditionsView(isAccepted: $termsAccepted)
                                .padding(.bottom, 10)
                            
                            registerButton
                            
                            Spacer()
                            
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
                
                alreadyHaveAnAccountButton
            }
            .ignoresSafeArea(.keyboard)
        }
        .background(
            Color.blackColor
        )
        .photosPicker(isPresented: $viewModel.openPicker, selection: $viewModel.selectedItem, matching: .images)
        .onChange(of: viewModel.selectedItem) { _, newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.imageData = data
                        viewModel.selectedImage = uiImage
                    }
                }
            }
        }
        .showGalleryPermissionAlert(show: $viewModel.showPermissionAlert)
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
            GenderCheckbox(gender: .hombre, selectedGender: $viewModel.gender)
            GenderCheckbox(gender: .mujer, selectedGender: $viewModel.gender)
            
            Spacer()
        }
    }
    
    private var imagePicker: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 120, height: 120)

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
            .onTapGesture {
                openPickerPublisher.send()
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
                .background(!termsAccepted ? Color.grayColor : Color.yellow)
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
            login: loginPublisher.eraseToAnyPublisher(),
            openPicker: openPickerPublisher.eraseToAnyPublisher()
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
                        .frame(width: 20, height: 20)
                    
                    if selectedGender == gender {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16) // Círculo interno más pequeño para dejar padding
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
