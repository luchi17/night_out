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
    
    private let openNotificationsPublisher = PassthroughSubject<Void, Never>()

    init(
        presenter: HomePresenter,
        mapPresenter: LocationsMapPresenter,
        feedPresenter: FeedPresenter,
        userPresenter: MyUserProfilePresenter,
        settingsPresenter: MyUserSettingsPresenter
    ) {
        self.presenter = presenter
        self.mapPresenter = mapPresenter
        self.feedPresenter = feedPresenter
        self.userPresenter = userPresenter
        self.settingsPresenter = settingsPresenter
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
                settingsPresenter: settingsPresenter
            )
                .presentationDetents([.large])
                .presentationBackground(.regularMaterial)
//                .presentationBackgroundInteraction(.enabled(upThrough: .large))
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
    }
    
    
    var topButtonView: some View {
        HStack(spacing: 0) {
            // Botón de perfil
            Button(action: {
                showMyProfile.toggle()
            }) {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.gray)
                    .font(.title)
            }
            
            Spacer()
            
            Image("appLogo") // Reemplaza con el nombre de tu imagen de logo
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 70)
            
            Spacer()
            
            // Botón de notificaciones
            Button(action: {
                openNotificationsPublisher.send()
            }) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.gray)
                    .font(.title)
            }
        }
        .padding(.top, 5)
        .padding(.horizontal, 20)
    }
}

private extension HomeView {
    
    func bindViewModel() {
        let input = HomePresenterImpl.ViewInputs(
            openNotifications: openNotificationsPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
