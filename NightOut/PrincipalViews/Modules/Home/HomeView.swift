import SwiftUI
import Combine

struct HomeView: View {
    
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var showMyProfile = false
    
    let presenter: HomePresenter
    let mapPresenter: LocationsMapPresenter
    let feedPresenter: FeedPresenter
    let userPresenter: MyUserProfilePresenter
    let settingsPresenter: MyUserSettingsPresenter
    let companySettingsPresenter: MyUserCompanySettingsPresenter
    let editProfilePresenter: MyUserEditProfilePresenter
    
    private let openNotificationsPublisher = PassthroughSubject<Void, Never>()
    private let openMessagesPublisher = PassthroughSubject<Void, Never>()
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private let updateProfileImagePublisher = PassthroughSubject<Void, Never>()
    
    @State private var updateProfileImage: Bool = false
    
    init(
        presenter: HomePresenter,
        mapPresenter: LocationsMapPresenter,
        feedPresenter: FeedPresenter,
        userPresenter: MyUserProfilePresenter,
        settingsPresenter: MyUserSettingsPresenter,
        companySettingsPresenter: MyUserCompanySettingsPresenter,
        editProfilePresenter: MyUserEditProfilePresenter
    ) {
        self.presenter = presenter
        self.mapPresenter = mapPresenter
        self.feedPresenter = feedPresenter
        self.userPresenter = userPresenter
        self.settingsPresenter = settingsPresenter
        self.companySettingsPresenter = companySettingsPresenter
        self.editProfilePresenter = editProfilePresenter
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
        .sheet(isPresented: $showMyProfile) {
            MyUserProfileView(
                presenter: userPresenter,
                settingsPresenter: settingsPresenter,
                companySettingsPresenter: companySettingsPresenter,
                editProfilePresenter: editProfilePresenter,
                updateProfileImage: $updateProfileImage
            )
                .presentationDetents([.large])
                .presentationBackground(.regularMaterial)
                .presentationDragIndicator(.visible)
        }
        .padding(.top, 20)
        .background(
            Image("fondo_azul")
                .resizable()
                .edgesIgnoringSafeArea(.all)
                .aspectRatio(contentMode: .fill)
        )
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
                    showMyProfile.toggle()
                }) {
                    profileImage
                }
                
                Button(action: {
                        #warning("TODO: open hub")
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
                #warning("TODO: open tinder")
            }) {
                Image("nightout")
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
            updateProfileImage: updateProfileImagePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
