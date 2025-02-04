import SwiftUI
import Combine

struct MyUserEditProfileView: View {
    
    @State private var showAlertDeleteUser = false
    @State private var showGenderSheet = false
    @State private var openSettings = false
    @State private var openCompanySettings = false
    
    @Binding private var closeAllSheets: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let saveInfoPublisher = PassthroughSubject<Void, Never>()
    private let logoutPublisher = PassthroughSubject<Void, Never>()
    private let confirmDeleteAccountPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: MyUserEditProfileViewModel
    let presenter: MyUserEditProfilePresenter
    let settingsPresenter: MyUserSettingsPresenter
    
    init(
        presenter: MyUserEditProfilePresenter,
        settingsPresenter: MyUserSettingsPresenter,
        closeAllSheets: Binding<Bool>
    ) {
        self.presenter = presenter
        self.settingsPresenter = settingsPresenter
        self._closeAllSheets = closeAllSheets
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack(spacing: 14) {
            
            HStack(spacing: 8) {
                Spacer()
                saveInfoButton
                
                if FirebaseServiceImpl.shared.getImUser() {
                    settingsButtonView
                }
            }

            topImageView
            
            VStack(alignment: .leading, spacing: 14) {
                TextField(viewModel.username, text: $viewModel.username)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color.clear) // Custom input background color
                    .foregroundColor(.white)
                    .overlay(
                            Rectangle()
                                .frame(height: 1) // Línea fina
                                .foregroundColor(.white), // Color de la línea
                            alignment: .bottom
                        )
                
                TextField(viewModel.fullname, text: $viewModel.fullname)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color.clear) // Custom input background color
                    .foregroundColor(.white)
                    .overlay(
                            Rectangle()
                                .frame(height: 1) // Línea fina
                                .foregroundColor(.white), // Color de la línea
                            alignment: .bottom
                        )

                if FirebaseServiceImpl.shared.getImUser() {
                    privateView
                    
                    genderView
                    
                    paymentsView
                    
                    participateView
                    
                } else {
                    
                    privateView
                        .padding(.top, 20)
                    
                    editCompanyInfoView
                        .padding(.top, 10)
                    
                    logoutView
                    
                    deleteAccountView
                    
                }
               
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(
            Image("fondo_azul")
                .resizable()
                .edgesIgnoringSafeArea(.all)
                .aspectRatio(contentMode: .fill)
        )
        .sheet(isPresented: $showGenderSheet) {
            GenderPicker(selectedGender: $viewModel.genderType, showSheet: $showGenderSheet)
        }
        .sheet(isPresented: $openSettings) {
            MyUserSettingsView(
                presenter: settingsPresenter,
                closeAllSheets: $closeAllSheets
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $openCompanySettings) {
//            MyUserSettingsView(
//                presenter: settingsPresenter,
//                closeAllSheets: $closeAllSheets
//            )
//            .presentationDetents([.large])
//            .presentationDragIndicator(.visible)
        }
        .alert(isPresented: $viewModel.showAlertMessage) {
            Alert(
                title: Text("Message"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showAlertDeleteUser) {
            Alert(
                title: Text("Confirm Deletion"),
                message: Text("Are you sure you want to delete your account? This action is irreversible."),
                primaryButton: .destructive(Text("Delete")) {
                    confirmDeleteAccountPublisher.send()
                },
                secondaryButton: .cancel()
            )
        }
        .overlay(
            Group {
                if viewModel.showProgress {
                    ProgressView(viewModel.progressMessage)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
            }
        )
        .onChange(of: viewModel.shouldCloseSheet, { olv, new in
            if new {
                closeAllSheets.toggle()
            }
        })
        .onChange(of: closeAllSheets, { oldValue, newValue in
            if newValue {
                dismiss()
            }
        })
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: viewModel.loading
        )
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    var topImageView: some View {
        VStack {
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else if let profileImageUrl = viewModel.profileImageUrl {
                KingFisherImage(url: URL(string: profileImageUrl))
                    .centerCropped(width: 100, height: 100, placeholder: {
                        ProgressView()
                    })
                    .clipShape(Circle())
            } else {
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }
            
            ImagePickerView(imageData: $viewModel.imageData, selectedImage: $viewModel.selectedImage) {
                Text("Cambiar imagen")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            .padding()
        }
        .padding(.top, 30)
    }
    
    var privateView: some View {
        HStack {
            Text("Perfil Privado")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Toggle(isOn: $viewModel.isPrivate) { }
                .toggleStyle(SwitchToggleStyle(tint: viewModel.isPrivate ? .pink : .gray))
        }
    }
    
    var genderView: some View {
        HStack {
            Text("Género")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            
            Text(viewModel.genderType == .male ? "Hombre" : "Mujer")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            Button {
                showGenderSheet.toggle()
            } label: {
                Image(systemName: "arrow.right")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
                    .padding(.leading, 5)
            }
        }
    }
    
    var paymentsView: some View {
        HStack(spacing: 8) {
            Text("Métodos de pago")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Image(systemName: "creditcard")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
    }
    
    var participateView: some View {
        HStack {
            Text("Perfil Privado")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Toggle(isOn: $viewModel.participate) { }
                .toggleStyle(SwitchToggleStyle(tint: viewModel.participate ? .pink : .gray))
        }
    }
    
    var saveInfoButton: some View {
        Button(action: {
            saveInfoPublisher.send()
        }) {
            Image(systemName: "checkmark")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
    }
    
    var settingsButtonView: some View {
        Button(action: {
            openSettings.toggle()
        }) {
            Image(systemName: "gear")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
    }
    
    var editCompanyInfoView: some View {
        Button(action: {
            openCompanySettings.toggle()
        }) {
            Text("Editar información de la empresa")
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    var logoutView: some View {
        Button(action: {
            logoutPublisher.send()
        }) {
            Text("Cerrar sesión")
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    var deleteAccountView: some View {
        Button(action: {
            showAlertDeleteUser.toggle()
        }) {
            Text("Borrar cuenta")
                .font(.system(size: 18))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

private extension MyUserEditProfileView {
    func bindViewModel() {
        let input = MyUserEditProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
            saveInfo: saveInfoPublisher.eraseToAnyPublisher(),
            logout: logoutPublisher.eraseToAnyPublisher(),
            confirmDeleteAccount: confirmDeleteAccountPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}



struct GenderSelectionView: View {
    @State private var showSheet = false
    @Binding private var selectedGender: Gender?
    
    var body: some View {
        VStack {
            Text("Seleccionado: \(selectedGender?.title ?? "Ninguno")")
                .font(.headline)
                .padding()
            
            Button("Seleccionar Género") {
                showSheet.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showSheet) {
            GenderPicker(selectedGender: $selectedGender, showSheet: $showSheet)
        }
    }
}

struct GenderPicker: View {
    @Binding var selectedGender: Gender?
    @Binding var showSheet: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Selecciona tu género")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 8)
            
            Button(action: {
                selectedGender = .male
                showSheet = false
            }) {
                Text("Hombre")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                selectedGender = .female
                showSheet = false
            }) {
                Text("Mujer")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button("Cancelar") {
                showSheet = false
            }
            .foregroundColor(.red)
            .padding(.top, 12)
        }
        .padding()
        .presentationDetents([.fraction(0.3)]) // Tamaño del BottomSheet
    }
}
