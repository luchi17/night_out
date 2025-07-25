import SwiftUI
import Combine

final class MyUserSettingsViewModel: ObservableObject {
    @Published var loading: Bool = false
    @Published var showAlertMessage: Bool = false
    @Published var alertMessage: String = ""
    @Published var progressMessage: String = ""
    @Published var showProgress: Bool = false
    @Published var appVersion: String = ""
    @Published var shouldCloseSheet: Bool = false
}

protocol MyUserSettingsPresenter {
    var viewModel: MyUserSettingsViewModel { get }
    func transform(input: MyUserSettingsPresenterImpl.ViewInputs)
}

final class MyUserSettingsPresenterImpl: MyUserSettingsPresenter {
    
    struct UseCases {
        let userDataUseCase: UserDataUseCase
        let signOutUseCase: SignOutUseCase
        let deleteAccountUseCase: DeleteAccountUseCase
    }

   
    struct Actions { }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let logout: AnyPublisher<Void, Never>
        let confirmDeleteAccount: AnyPublisher<Void, Never>
    }
    
    var viewModel: MyUserSettingsViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    let logoutSubject = PassthroughSubject<Void, Never>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        self.viewModel = MyUserSettingsViewModel()
        
        viewModel.progressMessage = "Please wait, we are deleting your account..."
    }
    
    func transform(input: MyUserSettingsPresenterImpl.ViewInputs) {
        
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.viewModel.appVersion = "App \(AppCoordinator.getAppVersion())"
            }
            .store(in: &cancellables)
        
        input
            .logout
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.logoutSubject.send()
            }
            .store(in: &cancellables)
        
        logoutSubject
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.signOutUseCase.execute()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { [weak self] error in
                if let error = error {
                    self?.viewModel.showAlertMessage = true
                    self?.viewModel.alertMessage = "Error logging out: \(error.localizedDescription)"
                }
            })
            .sink(receiveValue: { [weak self] _ in
                AppState.shared.shouldShowSplashVideo = false
                UserDefaults.clearAll()
                self?.viewModel.shouldCloseSheet = true
            })
            .store(in: &cancellables)

        input
            .confirmDeleteAccount
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                presenter.useCases.deleteAccountUseCase.execute()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.showProgress = loading
            }, onError: { _ in })
            .withUnretained(self)
            .sink(receiveValue: { presenter, errorMessage in
                presenter.viewModel.showAlertMessage = true
                if let errorMessage = errorMessage {
                    presenter.viewModel.alertMessage = "Error deleting account: \(errorMessage)"
                } else {
                    presenter.viewModel.alertMessage = "Account deleted successfully."
                    presenter.logoutSubject.send()
                }
            })
            .store(in: &cancellables)
    }
}


