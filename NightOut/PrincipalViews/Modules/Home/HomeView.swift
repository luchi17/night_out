import SwiftUI
import Combine

struct HomeView: View {
    
    @ObservedObject var viewModel: HomeViewModel
    
    let presenter: HomePresenter
    let mapPresenter: LocationsMapPresenter
    let feedPresenter: FeedPresenter
    let userPresenter: MyUserProfilePresenter
    let settingsPresenter: MyUserSettingsPresenter
    let companySettingsPresenter: MyUserCompanySettingsPresenter
    let editProfilePresenter: MyUserEditProfilePresenter
    let friendsPresenter: FriendsPresenter
    
    private let openNotificationsPublisher = PassthroughSubject<Void, Never>()
    private let openMessagesPublisher = PassthroughSubject<Void, Never>()
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let updateProfileImagePublisher = PassthroughSubject<Void, Never>()
    private let openTinderPublisher = PassthroughSubject<Void, Never>()
    private let openHubPublisher = PassthroughSubject<Void, Never>()
    
    
    @State private var updateProfileImage: Bool = false
    
    init(
        presenter: HomePresenter,
        mapPresenter: LocationsMapPresenter,
        feedPresenter: FeedPresenter,
        userPresenter: MyUserProfilePresenter,
        settingsPresenter: MyUserSettingsPresenter,
        companySettingsPresenter: MyUserCompanySettingsPresenter,
        friendsPresenter: FriendsPresenter,
        editProfilePresenter: MyUserEditProfilePresenter
    ) {
        self.presenter = presenter
        self.mapPresenter = mapPresenter
        self.feedPresenter = feedPresenter
        self.userPresenter = userPresenter
        self.settingsPresenter = settingsPresenter
        self.companySettingsPresenter = companySettingsPresenter
        self.editProfilePresenter = editProfilePresenter
        self.friendsPresenter = friendsPresenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        VStack {
            topButtonView
            
            HomePickerView(selectedTab: $viewModel.selectedTab)
            
            if viewModel.selectedTab == .map {
                LocationsMapView(presenter: mapPresenter)
            } else {
                FeedView(presenter: feedPresenter)
            }
        }
        .overlay {
            if viewModel.showGenderAlert {
                HomeGenderAlertView(
                    isPresented: $viewModel.showGenderAlert,
                    selectedGender: $viewModel.gender
                )
                
                Spacer()
            }
        }
        .sheet(isPresented: $viewModel.showMyProfile) {
            MyUserProfileView(
                presenter: userPresenter,
                settingsPresenter: settingsPresenter,
                companySettingsPresenter: companySettingsPresenter,
                editProfilePresenter: editProfilePresenter,
                friendsPresenter: friendsPresenter,
                updateProfileImage: $updateProfileImage
            )
            .presentationDetents([.large])
            .presentationBackground(.regularMaterial)
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showCompanyFirstAlert) {
            HomeCompanySheetView(close: {
                viewModel.showCompanyFirstAlert = false
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showUserFirstAlert) {
            TutorialSettingsView(close: {
                viewModel.showUserFirstAlert = false
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .padding(.top, 20)
        .background(
            Color.blackColor
                .edgesIgnoringSafeArea(.all)
        )
        .alert(isPresented: $viewModel.showNighoutAlert) {
            Alert(
                title: Text(viewModel.nighoutAlertTitle)
                    .foregroundColor(.white),
                message: Text(viewModel.nighoutAlertMessage)
                    .foregroundColor(.white),
                dismissButton: .default(Text("ACEPTAR"))
            )
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .onChange(of: updateProfileImage, { oldValue, newValue in
            updateProfileImagePublisher.send()
        })
        .onAppear {
            viewDidLoadPublisher.send()
        }
    }
    
    
    var topButtonView: some View {
        HStack(spacing: 0) {
            // Botón de perfil
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.showMyProfile.toggle()
                }) {
                    profileImage
                }
                
                Button(action: {
                    openHubPublisher.send()
                }) {
                    Text("HUB")
                        .foregroundStyle(.white)
                        .font(.system(size: 14))
                        .bold()
                }
            }
            .frame(width: 90)
            
            Spacer()
            
            Button(action: {
                openTinderPublisher.send()
            }) {
                Image(viewModel.nighoutLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 60)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                
                Spacer()
                // Botón de mensajes
                Button(action: {
                    openMessagesPublisher.send()
                }) {
                    Image("message_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.white)
                }
                
                // Botón de notificaciones
                Button(action: {
                    openNotificationsPublisher.send()
                }) {
                    Image("notificaciones")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 90)
            
        }
        .padding(.top, 30)
        .padding(.horizontal, 16)
    }
    
    var profileImage: some View {
        VStack {
            if let userImageUrl = viewModel.profileImageUrl {
                KingFisherImage(url: URL(string: userImageUrl))
                    .placeholder({
                        Image("profile")
                            .clipShape(Circle())
                    })
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
        }
    }
}

private extension HomeView {
    
    func bindViewModel() {
        let input = HomePresenterImpl.ViewInputs(
            openNotifications: openNotificationsPublisher.eraseToAnyPublisher(),
            openMessages: openMessagesPublisher.eraseToAnyPublisher(),
            viewDidLoad: viewDidLoadPublisher.eraseToAnyPublisher(),
            updateProfileImage: updateProfileImagePublisher.eraseToAnyPublisher(),
            openHub: openHubPublisher.eraseToAnyPublisher(),
            openTinder: openTinderPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}


struct HomeGenderAlertView: View {
    @Binding var isPresented: Bool
    @Binding var selectedGender: Gender?
    
    var body: some View {
        
        Rectangle()
            .stroke(lineWidth: 1)
            .foregroundStyle(.blue)
            .background(Color.blackColor)
            .overlay {
                VStack(alignment: .leading, spacing: 20) {
                    Text("¡Vaya! No tenemos registrado tu género.")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.white)
                    
                    HStack {
                        GenderCheckbox(gender: .hombre, selectedGender: $selectedGender)
                        GenderCheckbox(gender: .mujer, selectedGender: $selectedGender)
                        
                        Spacer()
                    }
                }
                .padding()
            }
            .transition(.opacity)
            .shadow(radius: 10)
            .background(Color.blackColor.opacity(0.7))
            .frame(width: 300, height: 120)
            .padding(40)
            .onChange(of: selectedGender) { oldValue, newValue in
                dismissWithDelay()
            }
    }
    
    private func dismissWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation {
                isPresented = false
            }
        }
    }
}
