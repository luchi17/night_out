import SwiftUI
import Combine

struct MyUserSettingsView: View {
    
    @State private var showAlertDeleteUser = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsAndConditions = false
    @State private var showTutorial = false
    
    @Binding private var closeAllSheets: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let logoutPublisher = PassthroughSubject<Void, Never>()
    private let confirmDeleteAccountPublisher = PassthroughSubject<Void, Never>()
    
    @ObservedObject var viewModel: MyUserSettingsViewModel
    let presenter: MyUserSettingsPresenter
    
    init(
        presenter: MyUserSettingsPresenter,
        closeAllSheets: Binding<Bool>
    ) {
        self.presenter = presenter
        self._closeAllSheets = closeAllSheets
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                topView
                
                // Sección Legal
                SectionView(iconName: "flag", title: "Legal") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Política de Privacidad")
                            .font(.system(size: 16))
                            .foregroundColor(.grayColor)
                            .onTapGesture {
                                showPrivacyPolicy.toggle()
                            }
                        Text("Términos y Condiciones")
                            .font(.system(size: 16))
                            .foregroundColor(.grayColor)
                            .onTapGesture {
                                showTermsAndConditions.toggle()
                            }
                    }
                }
                
                SectionView(iconName: "envelope", title: "Contáctanos") {
                    Text(AttributedString("corporativo@formatink.com"))
                        .foregroundColor(.grayColor)
                        .font(.system(size: 16))
                        .onTapGesture {
                            if let url = URL(string: "mailto:corporativo@formatink.com") {
                                UIApplication.shared.open(url)
                            }
                        }
                }
                
                Text("Tutorial")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                    .onTapGesture {
                        showTutorial.toggle()
                    }
                
                HStack {
                    Image(systemName: "arrow.right.square")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                    Text("Cerrar Sesión")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .onTapGesture {
                    logoutPublisher.send()
                }
                
                HStack {
                    Image(systemName: "trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                    Text("Borrar Cuenta")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .onTapGesture {
                    showAlertDeleteUser.toggle()
                }
                
                Text(viewModel.appVersion)
                    .font(.system(size: 14))
                    .foregroundColor(.grayColor)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
        }
        .background(
            Color.blackColor
                .edgesIgnoringSafeArea(.all)
        )
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
        .sheet(isPresented: $showTutorial) {
            TutorialSettingsView(close: {
                showTutorial = false
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTermsAndConditions) {
            SettingsTermsAndConditionsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
                dismiss()
            }
        })
        .applyStates(error: nil, isIdle: viewModel.loading)
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    var topView: some View {
        HStack {
            Text("Configuraciones")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 40)
                .padding(.bottom, 15)
            
            Spacer()
        
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        
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
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            content()
        }
    }
}
