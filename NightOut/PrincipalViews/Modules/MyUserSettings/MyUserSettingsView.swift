import SwiftUI
import Combine

struct MyUserSettingsView: View {
    
    @State private var showAlertDeleteUser = false
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let logoutPublisher = PassthroughSubject<Void, Never>()
    private let confirmDeleteAccountPublisher = PassthroughSubject<Void, Never>()
    //    private let termsConditionsPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: MyUserSettingsViewModel
    let presenter: MyUserSettingsPresenter
    
    init(
        presenter: MyUserSettingsPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Título
                Text("Configuraciones")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                // Sección Legal
                SectionView(iconName: "gavel", title: "Legal") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Privacy Policy")
                            .foregroundColor(.gray)
                            .onTapGesture {
                                // Acción para Privacy Policy
                            }
                        Text("Terms and Conditions")
                            .foregroundColor(.gray)
                            .onTapGesture {
                                // Acción para Terms and Conditions
                            }
                    }
                }
                
                
                // Sección Contact Us
                SectionView(iconName: "envelope", title: "Contact Us") {
                    
                    Button(action: {
#warning("TODO: done in android?")
                    }) {
                        Text("For feedback, suggestions, and collaborations")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                
                // Sección Log Out
                SectionView(iconName: "arrow.right.square", title: "Log Out") {
                    Button(action: {
                        logoutPublisher.send()
                    }) {
                        Text("Log Out")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                
                // Sección Delete Account
                SectionView(iconName: "trash", title: "Delete Account") {
                    Button(action: {
                        showAlertDeleteUser.toggle()
                    }) {
                        Text("Delete Account")
                            .foregroundColor(.white)
                    }
                }
                
                // Versión de la aplicación
                Text(viewModel.appVersion)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
        }
        .background(Color.blue) // Cambiar a un color específico si tienes un color personalizado
        .ignoresSafeArea()
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
        .applyStates(error: nil, isIdle: viewModel.loading)
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
}

private extension MyUserSettingsView {
    func bindViewModel() {
        let input = MyUserSettingsPresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            logout: logoutPublisher.eraseToAnyPublisher(),
            confirmDeleteAccount: confirmDeleteAccountPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}



struct SectionView<Content: View>: View {
    let iconName: String
    let title: String
    let content: () -> Content
    
    init(iconName: String, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.iconName = iconName
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            content()
        }
    }
}

