import SwiftUI
import Combine
import CoreLocation
import PhotosUI

struct SignupCompanyView: View {
    
    @ObservedObject var viewModel: SignupCompanyViewModel
    @State private var showTagSelection = false
    @State private var selectedTime = Date()
    @State private var showTimePicker = false
    @State private var showLocation = false
    @State private var locationName = ""
    @State private var locationModel = LocationModel()
    
    let presenter: SignupCompanyPresenter
    
    private let signupCompanyPublisher = PassthroughSubject<Void, Never>()
    private let loginPublisher = PassthroughSubject<Void, Never>()
    private let openPickerPublisher = PassthroughSubject<Void, Never>()
    
    init(
        presenter: SignupCompanyPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack(spacing: 10) {

            Spacer()
            
            Image("nightout")
                .resizable()
                .scaledToFit()
                .frame(height: 70)
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
            
            TextField("", text: $viewModel.email, prompt: Text("Email...").foregroundColor(.white))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.all, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
                )
                .foregroundColor(.white)
                .accentColor(.white)
            
            SecureField("", text: $viewModel.password, prompt: Text("Contraseña...").foregroundColor(.white))
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.all, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1)
                )
                .foregroundColor(.white)
                .accentColor(.white)
                .padding(.bottom, 10)
            
            locationButton
            TimeButtonView(
                title: "APERTURA",
                selectedTimeString: $viewModel.startTime
            )
            TimeButtonView(
                title: "CIERRE",
                selectedTimeString: $viewModel.endTime
            )
            selectTagButton
            
            Spacer()
            
            HStack(spacing: 20) {
                registerButton
                signInButton
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 20)
        .background(
            Color.blackColor
        )
        .sheet(
            isPresented: $showLocation,
            onDismiss: {
                viewModel.locationString = locationModel.coordinate.location.latitude.description + "," + locationModel.coordinate.location.longitude.description
                locationName = locationModel.name.isEmpty ? ( "(" + viewModel.locationString + ")") : locationModel.name
                
            }, content: {
                SignupMapView(locationModel: $locationModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
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
            signupCompanyPublisher.send()
        }) {
            Text("Registrarse")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.grayColor)
                .cornerRadius(25)
        }
    }
    
    private var signInButton: some View {
        Button(action: {
            loginPublisher.send()
        }) {
            Text("Iniciar Sesión")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.grayColor)
                .cornerRadius(25)
        }
    }
    
    private var locationButton: some View {
        Button(action: {
            showLocation.toggle()
        }) {
            Text(locationName.isEmpty ? "LOCALIZACIÓN" : locationName)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.grayColor)
                .cornerRadius(25)
        }
    }
    
    private var selectTagButton: some View {
        Button(action: {
            showTagSelection.toggle()
        }) {
            Text(showTagSelection ? "VESTIMENTA" : viewModel.selectedTag.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.grayColor)
                .cornerRadius(25)
        }
        .confirmationDialog("Elija vestimenta", isPresented: $showTagSelection) {
            Button(LocationSelectedTag.sportCasual.title) { viewModel.selectedTag = .sportCasual }
            Button(LocationSelectedTag.informal.title) { viewModel.selectedTag = .informal  }
            Button(LocationSelectedTag.semiInformal.title) { viewModel.selectedTag = .semiInformal  }
            Button("Cancel", role: .cancel) {
                viewModel.selectedTag = .none
            }
        } message: {
            Text("Elija vestimenta")
        }
    }
    
}

private extension SignupCompanyView {
    
    func bindViewModel() {
        let input = SignupCompanyPresenterImpl.ViewInputs(
            signupCompany: signupCompanyPublisher.eraseToAnyPublisher(),
            login: loginPublisher.eraseToAnyPublisher(),
            openPicker: openPickerPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}



