import SwiftUI
import Combine
import CoreLocation

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
    
    init(
        presenter: SignupCompanyPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Logo
            
            Spacer()
            
            ImagePickerView(
                imageData: $viewModel.imageData,
                selectedImage: $viewModel.selectedImage
            ) {
                VStack {
                    if let selectedImage = viewModel.selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                        
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .foregroundColor(.blue) // Color del ícono
                            .padding()
                    }
                }
            }
            
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
            TimeButtonView(
                title: "START TIME",
                selectedTimeString: $viewModel.startTime
            )
            TimeButtonView(
                title: "END TIME",
                selectedTimeString: $viewModel.endTime
            )
            selectTagButton
            
            Spacer()
            
            HStack(spacing: 20) {
                registerButton
                signInButton
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        //        }
        .background(
            Image("imagen_inicio")
                .resizable()
                .edgesIgnoringSafeArea(.all)
                .aspectRatio(contentMode: .fill)
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
        .showToast(
            error: (
                type: viewModel.toast,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toast = nil
                }
            ),
            isIdle: viewModel.loading,
            toastExtraPadding: true
        )
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
    
    private var locationButton: some View {
        Button(action: {
            showLocation.toggle()
        }) {
            Text(locationName.isEmpty ? "LOCATION" : locationName)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .shadow(radius: 4)
        }
    }
    
    private var selectTagButton: some View {
        Button(action: {
            showTagSelection.toggle()
        }) {
            Text(showTagSelection ? "SELECT TAG" : viewModel.selectedTag.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .shadow(radius: 4)
        }
        .confirmationDialog("Elija etiqueta", isPresented: $showTagSelection) {
            Button(LocationSelectedTag.sportCasual.title) { viewModel.selectedTag = .sportCasual }
            Button(LocationSelectedTag.informal.title) { viewModel.selectedTag = .informal  }
            Button(LocationSelectedTag.semiInformal.title) { viewModel.selectedTag = .semiInformal  }
            Button("Cancel", role: .cancel) {
                viewModel.selectedTag = .none
            }
        } message: {
            Text("Elija etiqueta")
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



