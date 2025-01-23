
import SwiftUI
import Combine

class HomeCoordinator {
    
    private let actions: HomePresenterImpl.Actions
    private let mapActions: LocationsMapPresenterImpl.Actions
    private let feedActions: FeedPresenterImpl.Actions
    private let settingsActions: MyUserSettingsPresenterImpl.Actions
    private let locationManager: LocationManager
    
    init(actions: HomePresenterImpl.Actions, mapActions: LocationsMapPresenterImpl.Actions, feedActions : FeedPresenterImpl.Actions, settingsActions: MyUserSettingsPresenterImpl.Actions, locationManager: LocationManager) {
        self.actions = actions
        self.mapActions = mapActions
        self.locationManager = locationManager
        self.feedActions = feedActions
        self.settingsActions = settingsActions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = HomePresenterImpl(
            useCases: .init(),
            actions: actions
        )
        let mapPresenter = LocationsMapPresenterImpl(
            useCases: .init(companyLocationsUseCase: CompanyLocationsUseCaseImpl(repository: LocationRepositoryImpl.shared)),
            actions: mapActions,
            locationManager: locationManager
        )
        let feedPresenter = FeedPresenterImpl(
            useCases: .init(
                postsUseCase: PostsUseCaseImpl(repository: PostsRepositoryImpl.shared),
                followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared),
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared), companyDataUseCase: CompanyDataUseCaseImpl(repository: AccountRepositoryImpl.shared)),
            actions: feedActions
        )
        let userPresenter = MyUserProfilePresenterImpl(
            useCases: .init(
                followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared),
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: .init()
        )
        
        let settingsPresenter = MyUserSettingsPresenterImpl(
            useCases: .init(
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared),
                signOutUseCase: SignOutUseCaseImpl(repository: AccountRepositoryImpl.shared),
                deleteAccountUseCase: DeleteAccountUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: settingsActions
        )
        
        HomeView(
            presenter: presenter,
            mapPresenter: mapPresenter,
            feedPresenter: feedPresenter,
            userPresenter: userPresenter,
            settingsPresenter: settingsPresenter
        )
    }
}

