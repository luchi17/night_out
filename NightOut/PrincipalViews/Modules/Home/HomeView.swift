import SwiftUI
import Combine

struct HomeView: View {
    
    @ObservedObject var viewModel: HomeViewModel
    
    let presenter: HomePresenter
    let mapPresenter: LocationsMapPresenter
    let feedPresenter: FeedPresenter
    
    private let openNotificationsPublisher = PassthroughSubject<Void, Never>()
    private let openProfilePublisher = PassthroughSubject<Void, Never>()
    init(
        presenter: HomePresenter,
        mapPresenter: LocationsMapPresenter,
        feedPresenter: FeedPresenter
    ) {
        self.presenter = presenter
        self.mapPresenter = mapPresenter
        self.feedPresenter = feedPresenter
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
        .padding(.top, 20)
        .background(.blue)
        .navigationBarHidden(true)
    }
    
    
    var topButtonView: some View {
        // Parte superior de la pantalla
        HStack(spacing: 0) {
            // Botón de perfil
            Button(action: {
                openProfilePublisher.send()
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
            openProfile: openProfilePublisher.eraseToAnyPublisher(),
            openNotifications: openNotificationsPublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
