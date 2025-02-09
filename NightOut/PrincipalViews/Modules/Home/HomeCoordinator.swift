
import SwiftUI
import Combine

class HomeCoordinator {
    
    private let actions: HomePresenterImpl.Actions
    private let mapActions: LocationsMapPresenterImpl.Actions
    private let feedActions: FeedPresenterImpl.Actions
    private let profileActions: MyUserProfilePresenterImpl.Actions
    private let locationManager: LocationManager
    
    private let reloadSubject = PassthroughSubject<Void, Never>()
                                        
    init(actions: HomePresenterImpl.Actions, mapActions: LocationsMapPresenterImpl.Actions, feedActions : FeedPresenterImpl.Actions, profileActions: MyUserProfilePresenterImpl.Actions, locationManager: LocationManager) {
        self.actions = actions
        self.mapActions = mapActions
        self.locationManager = locationManager
        self.feedActions = feedActions
        self.profileActions = profileActions
    }
    
    @ViewBuilder
    func build() -> some View {
        let presenter = HomePresenterImpl(
            useCases: .init(),
            actions: actions,
            reloadSubject: reloadSubject
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
            actions: feedActions,
            input: .init(reload: reloadSubject.eraseToAnyPublisher())
        )
        let userPresenter = MyUserProfilePresenterImpl(
            useCases: .init(
                followUseCase: FollowUseCaseImpl(repository: PostsRepositoryImpl.shared),
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: profileActions
        )
        
        let editProfilePresenter = MyUserEditProfilePresenterImpl(
            useCases: .init(
                saveUserUseCase: SaveUserUseCaseImpl(repository: AccountRepositoryImpl.shared),
                saveCompanyUseCase: SaveCompanyUseCaseImpl(repository: AccountRepositoryImpl.shared),
                signOutUseCase: SignOutUseCaseImpl(repository: AccountRepositoryImpl.shared),
                deleteAccountUseCase: DeleteAccountUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: .init(backToLogin: profileActions.backToLogin)
        )
        
        let settingsPresenter = MyUserSettingsPresenterImpl(
            useCases: .init(
                userDataUseCase: UserDataUseCaseImpl(repository: AccountRepositoryImpl.shared),
                signOutUseCase: SignOutUseCaseImpl(repository: AccountRepositoryImpl.shared),
                deleteAccountUseCase: DeleteAccountUseCaseImpl(repository: AccountRepositoryImpl.shared)
            ),
            actions: .init()
        )
        
        let companySettingsPresenter = MyUserCompanySettingsPresenterImpl(
            useCases: .init(saveCompanyDataUseCase: SaveCompanyUseCaseImpl(repository: AccountRepositoryImpl.shared)),
            actions: .init()
        )

        HomeView(
            presenter: presenter,
            mapPresenter: mapPresenter,
            feedPresenter: feedPresenter,
            userPresenter: userPresenter,
            settingsPresenter: settingsPresenter,
            companySettingsPresenter: companySettingsPresenter,
            editProfilePresenter: editProfilePresenter
        )
    }
}

