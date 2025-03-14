import SwiftUI
import Combine
import PhotosUI

struct MyUserEditProfileView: View {
    
    @State private var showAlertDeleteUser = false
    @State private var showGenderSheet = false
    @State private var openSettings = false
    @State private var openCompanySettings = false
    @State private var openMetodosDePago = false
    
    @Binding private var closeAllSheets: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let saveInfoPublisher = PassthroughSubject<Void, Never>()
    private let logoutPublisher = PassthroughSubject<Void, Never>()
    private let confirmDeleteAccountPublisher = PassthroughSubject<Void, Never>()
    private let openPickerPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: MyUserEditProfileViewModel
    let presenter: MyUserEditProfilePresenter
    let settingsPresenter: MyUserSettingsPresenter
    let companySettingsPresenter: MyUserCompanySettingsPresenter
    
    init(
        presenter: MyUserEditProfilePresenter,
        settingsPresenter: MyUserSettingsPresenter,
        companySettingsPresenter: MyUserCompanySettingsPresenter,
        closeAllSheets: Binding<Bool>
    ) {
        self.presenter = presenter
        self.settingsPresenter = settingsPresenter
        self.companySettingsPresenter = companySettingsPresenter
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
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                    
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
            Color.blackColor
                .edgesIgnoringSafeArea(.all)
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
        .sheet(isPresented: $openCompanySettings, onDismiss: {
            openCompanySettings = false
            viewDidLoadPublisher.send()
        }) {
            MyUserCompanySettingsView(presenter: companySettingsPresenter)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $openMetodosDePago) {
            MyPaymentMethodsView(onClose: {
                openMetodosDePago = false
            })
            .presentationDetents([.large])
        }
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
        .onTapGesture {
             hideKeyboard()
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            
            Text("Cambiar imagen")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 8)
                .padding()
                .onTapGesture {
                    openPickerPublisher.send()
                }
        }
        .padding(.top, 30)
    }
    
    var privateView: some View {
        HStack {
            Text("Perfil Privado")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Toggle(isOn: $viewModel.isPrivate) { }
                .toggleStyle(SwitchToggleStyle(tint: viewModel.isPrivate ? .pink : .grayColor))
        }
    }
    
    var genderView: some View {
        HStack {
            Text("Género")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            
            Text(viewModel.genderType?.title ?? "Selecciona")
                .font(.system(size: 16, weight: .medium))
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
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Image(systemName: "creditcard")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
        .onTapGesture {
            openMetodosDePago = true
        }
    }
    
    var participateView: some View {
        HStack {
            Text("Participar en Social NightOut")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Toggle(isOn: $viewModel.participate) { }
                .toggleStyle(SwitchToggleStyle(tint: viewModel.participate ? .pink : .grayColor))
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
            openSettings = true
        }) {
            Image(systemName: "gear")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
    }
    
    var editCompanyInfoView: some View {
        Button(action: {
            openCompanySettings = true
        }) {
            Text("Editar información de la empresa")
                .font(.system(size: 16))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.grayColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    var logoutView: some View {
        Button(action: {
            logoutPublisher.send()
        }) {
            Text("Cerrar sesión")
                .font(.system(size: 16))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.grayColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    var deleteAccountView: some View {
        Button(action: {
            showAlertDeleteUser.toggle()
        }) {
            Text("Borrar cuenta")
                .font(.system(size: 16))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.grayColor)
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
            confirmDeleteAccount: confirmDeleteAccountPublisher.eraseToAnyPublisher(),
            openPicker: openPickerPublisher.eraseToAnyPublisher()
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
        VStack {
            Text("Selecciona tu género")
                .foregroundStyle(.white)
                .font(.system(size: 18, weight: .bold))
                .padding(.top, 8)
            
            Spacer()
            
            HStack {
                Spacer()
                
                GenderCheckbox(gender: .hombre, selectedGender: $selectedGender)
                GenderCheckbox(gender: .mujer, selectedGender: $selectedGender)
                
                Spacer()
            }
            
            Spacer()

            Button("Cancelar") {
                showSheet = false
            }
            .foregroundColor(.red)
            .padding(.bottom, 20)
            
        }
        .padding()
        .onChange(of: selectedGender) { oldValue, newValue in
            showSheet = false
        }
        .presentationDetents([.fraction(0.22)])
    }
}
