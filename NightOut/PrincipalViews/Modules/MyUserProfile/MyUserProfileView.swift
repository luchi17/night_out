import SwiftUI
import Combine

struct MyUserProfileView: View {
    
    @State private var showShareSheet = false
    @State private var showEditSheet = false
    @State private var showFollowersSheet = false
    @State private var showCompanyMenu = false
    
    @State private var closeAllSheets = false
    @Binding private var updateProfileImage: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let goToLoginPublisher = PassthroughSubject<Void, Never>()
    private let openMenuSelectionPublisher = PassthroughSubject<CompanyMenuSelection, Never>()
    
    @ObservedObject var viewModel: MyUserProfileViewModel
    @ObservedObject var levelsViewModel: LevelsViewModel
    
    let presenter: MyUserProfilePresenter
    let settingsPresenter: MyUserSettingsPresenter
    let friendsPresenter: FriendsPresenter
    let editProfilePresenter: MyUserEditProfilePresenter
    let companySettingsPresenter: MyUserCompanySettingsPresenter
    
    init(
        presenter: MyUserProfilePresenter,
        settingsPresenter: MyUserSettingsPresenter,
        companySettingsPresenter: MyUserCompanySettingsPresenter,
        editProfilePresenter: MyUserEditProfilePresenter,
        friendsPresenter: FriendsPresenter,
        updateProfileImage: Binding<Bool>
    ) {
        self.presenter = presenter
        self.settingsPresenter = settingsPresenter
        self.companySettingsPresenter = companySettingsPresenter
        self.editProfilePresenter = editProfilePresenter
        self.friendsPresenter = friendsPresenter
        self._updateProfileImage = updateProfileImage
        viewModel = presenter.viewModel
        levelsViewModel = LevelsViewModel()
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            HStack {
                if !FirebaseServiceImpl.shared.getImUser() {
                    Button(action: {
                        showCompanyMenu.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                }
                
                editProfileButton
            }
            
            if let profileImageUrl = viewModel.profileImageUrl {
                KingFisherImage(url: URL(string: profileImageUrl))
                    .centerCropped(width: 100, height: 100, placeholder: {
                        ProgressView()
                    })
                    .clipShape(Circle())
                    .padding(.top, 40)
            } else {
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .padding(.top, 40)
            }
            
            Text(viewModel.fullname)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 8)
            
            Text(viewModel.username)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            shareProfileButton
            
            HStack(spacing: 8) {
                CounterView(count: viewModel.followersCount, label: "Seguidores")
                    .onTapGesture {
                        showFollowersSheet.toggle()
                    }
                if FirebaseServiceImpl.shared.getImUser() {
                    CounterView(count: viewModel.discosCount, label: "Discotecas")
                    CounterView(count: viewModel.copasCount, label: "Copas")
                }
            }
            .padding(.top, 16)
            
            if FirebaseServiceImpl.shared.getImUser() && !levelsViewModel.levelList.isEmpty {
                RookieLevelsView(viewModel: levelsViewModel)
            }
            
            Spacer()
            
        }
        .background(
            Color.blackColor
        )
        .sheet(isPresented: $showShareSheet) {
            if let currentId = FirebaseServiceImpl.shared.getCurrentUserUid() {
                // Presentar el ActivityViewController para compartir
                ShareSheet(activityItems: ["¡Echa un vistazo a este perfil en NightOut! nightout://profile/\(currentId)"])
            }
        }
        .sheet(isPresented: $showEditSheet, onDismiss: {
            viewDidLoadPublisher.send()
            if let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() {
                levelsViewModel.loadUserLevels(profileId: currentUserId)
            }
            updateProfileImage.toggle()
        }) {
            MyUserEditProfileView(
                presenter: editProfilePresenter,
                settingsPresenter: settingsPresenter,
                companySettingsPresenter: companySettingsPresenter,
                closeAllSheets: $closeAllSheets
            )
             .presentationDetents([.large])
             .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFollowersSheet) {
            FriendsView(
                presenter: friendsPresenter,
                followerIds: viewModel.followers
            )
            .presentationDetents([.large])
             .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCompanyMenu) {
            CompanyMenu(
                selection: $viewModel.companyMenuSelection,
                showSheet: $showCompanyMenu
            )
        }
        .onChange(of: closeAllSheets, { oldValue, newValue in
            if newValue {
                goToLoginPublisher.send()
                dismiss()
            }
        })
        .onAppear {
            viewDidLoadPublisher.send()
            if let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() {
                levelsViewModel.loadUserLevels(profileId: currentUserId)
            }
        }
    }
    
    var editProfileButton: some View {
        HStack {
            Spacer()
            Button(action: {
                showEditSheet.toggle()
            }) {
                Text("Editar".uppercased())
                    .font(.system(size: 16))
                    .bold()
                    .foregroundColor(.white)
                    .padding(.all, 14)
                    .background(Color.grayColor)
                    .cornerRadius(25)
            }
            .padding(.trailing, 16)
        }
        .padding(.top, 16)
    }
    
    var shareProfileButton: some View {
        Button(action: {
            self.showShareSheet.toggle()
        }) {
            Text("Compartir perfil".uppercased())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.all, 14)
                .background(Color.grayColor)
                .cornerRadius(25)
        }
        .padding(.top, 16)
    }
}

private extension MyUserProfileView {
    func bindViewModel() {
        let input = MyUserProfilePresenterImpl.ViewInputs(
            viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
            goToLogin: goToLoginPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}

private struct CompanyMenu: View {
    
    @Binding var selection: CompanyMenuSelection?
    @Binding var showSheet: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: {
                    selection = .lectorEntradas
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.lectorEntradas.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    selection = .ventas
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.ventas.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    selection = .metodosDePago
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.metodosDePago.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    selection = .gestorEventos
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.gestorEventos.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    selection = .publicidad
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.publicidad.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.leading, 20)
            
            Spacer()
        }
        .presentationDetents([.fraction(0.25)])
        .presentationBackground(Color.grayColor)
        .presentationDragIndicator(.visible)
    }
}

enum CompanyMenuSelection {
    case lectorEntradas
    case ventas
    case metodosDePago
    case gestorEventos
    case publicidad
    
    var title: String {
        switch self {
        case .lectorEntradas:
            return "Lector de entradas"
        case .ventas:
            return "Ventas"
        case .metodosDePago:
            return "Métodos de pago"
        case .gestorEventos:
            return "Gestor eventos"
        case .publicidad:
            return "Publicidad"
        }
    }
}
