import SwiftUI
import Combine

struct MyUserSettingsView: View {
    
    @State private var showAlertDeleteUser = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsAndConditions = false
    
    @Environment(\.dismiss) private var dismiss
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let logoutPublisher = PassthroughSubject<Void, Never>()
    private let confirmDeleteAccountPublisher = PassthroughSubject<Void, Never>()
    
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
                
                topView
                
                // Sección Legal
                SectionView(iconName: "flag", title: "Legal") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Privacy Policy")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .onTapGesture {
                                showPrivacyPolicy.toggle()
                            }
                        Text("Terms and Conditions")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .onTapGesture {
                                showTermsAndConditions.toggle()
                            }
                    }
                }
                
                SectionView(iconName: "envelope", title: "Contact Us") {
                    
                    Button(action: {
#warning("TODO: done in android?")
                    }) {
                        Text("For feedback, suggestions, and collaborations")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                
                SectionView(iconName: "arrow.right.square", title: "Log Out") {
                    Button(action: {
                        logoutPublisher.send()
                    }) {
                        Text("Log Out")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                
                SectionView(iconName: "trash", title: "Delete Account") {
                    Button(action: {
                        showAlertDeleteUser.toggle()
                    }) {
                        Text("Delete Account")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                
                Text(viewModel.appVersion)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
        }
        .background(
            Image("fondo_azul")
                .resizable()
                .edgesIgnoringSafeArea(.all)
                .aspectRatio(contentMode: .fill)
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
        .applyStates(error: nil, isIdle: viewModel.loading)
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
//    var topView: some View {
//        VStack(spacing: 12) {
//            HStack {
//                Spacer()
//                
//                Button(action: {
//                    dismiss()
//                }) {
//                    Image(systemName: "xmark")
//                        .foregroundStyle(.white)
//                        .font(.system(size: 20, weight: .bold))
//                }
//            }
//            HStack {
//                
//                Spacer()
//            }
//        }
//        .padding(.top, 16)
//        .padding(.horizontal, 16)
//    }
    
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
