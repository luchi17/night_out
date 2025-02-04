import SwiftUI
import Combine


final class MyUserEditProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = ""
    @Published var fullname: String = ""
    @Published var genderType: Gender?
    @Published var isPrivate: Bool = false
    @Published var participate: Bool = false // TODO
    @Published var imageData: Data? = nil
    @Published var selectedImage: UIImage?
    
    @Published var toast: ToastType?
    @Published var shouldCloseSheet: Bool = false
    @Published var loading: Bool = false
    @Published var showAlertMessage: Bool = false
    @Published var alertMessage: String = ""
    @Published var progressMessage: String = ""
    @Published var showProgress: Bool = false
    
    
    init(profileImageUrl: String?, username: String?, fullname: String?, gender: Gender?, profile: ProfileType?) {
        self.profileImageUrl = profileImageUrl
        self.username = username ?? "Username no disponible"
        self.fullname = fullname ?? "Fullname no disponible"
        self.genderType = gender
        self.isPrivate = profile == .privateProfile
    }
    
    init() {
        
    }
}

protocol MyUserEditProfilePresenter {
    var viewModel: MyUserEditProfileViewModel { get }
    func transform(input: MyUserEditProfilePresenterImpl.ViewInputs)
}

final class MyUserEditProfilePresenterImpl: MyUserEditProfilePresenter {
    
    struct UseCases {
        let saveUserUseCase: SaveUserUseCase
        let saveCompanyUseCase: SaveCompanyUseCase
        let signOutUseCase: SignOutUseCase
        let deleteAccountUseCase: DeleteAccountUseCase
    }
    
    struct Actions {
        let backToLogin: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let saveInfo: AnyPublisher<Void, Never>
        let logout: AnyPublisher<Void, Never>
        let confirmDeleteAccount: AnyPublisher<Void, Never>
    }
    
    var viewModel: MyUserEditProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private var userModel: UserModel?
    private var companyModel: CompanyModel?
    
    let logoutSubject = PassthroughSubject<Void, Never>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases

        viewModel = MyUserEditProfileViewModel()
    }
    
    func transform(input: MyUserEditProfilePresenterImpl.ViewInputs) {
        
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                if FirebaseServiceImpl.shared.getImUser() {
                    presenter.userModel = UserDefaults.getUserModel()
                    presenter.viewModel = MyUserEditProfileViewModel(
                        profileImageUrl: presenter.userModel?.image,
                        username: presenter.userModel?.username,
                        fullname: presenter.userModel?.fullname,
                        gender: presenter.userModel?.genderType,
                        profile: presenter.userModel?.profileType ?? .publicProfile
                    )
                } else {
                    presenter.companyModel = UserDefaults.getCompanyUserModel()
                    presenter.viewModel = MyUserEditProfileViewModel(
                        profileImageUrl: presenter.companyModel?.imageUrl,
                        username: presenter.companyModel?.username,
                        fullname: presenter.companyModel?.fullname,
                        gender: nil,
                        profile: presenter.companyModel?.profileType ?? .publicProfile
                    )
                }
            }
            .store(in: &cancellables)
        
        input
            .saveInfo
            .withUnretained(self)
            .flatMap { presenter, _ -> AnyPublisher<String?, Never> in
                guard let imageData = presenter.viewModel.imageData else {
                    return Just(nil)
                        .eraseToAnyPublisher()
                }
                return presenter.useCases.saveCompanyUseCase.executeGetImageUrl(imageData: imageData)
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .flatMap { presenter, imageUrl in
                if !FirebaseServiceImpl.shared.getImUser() {
                    let model = CompanyModel(
                        email: presenter.companyModel?.email,
                        endTime: presenter.companyModel?.endTime,
                        selectedTag: presenter.companyModel?.selectedTag,
                        fullname: presenter.viewModel.fullname,
                        username: presenter.viewModel.username.lowercased(),
                        imageUrl: imageUrl ?? presenter.companyModel?.imageUrl,
                        location: presenter.companyModel?.location,
                        startTime: presenter.companyModel?.startTime,
                        uid: FirebaseServiceImpl.shared.getCurrentUserUid()!,
                        entradas: presenter.companyModel?.entradas,
                        payment: presenter.companyModel?.payment,
                        ticketsSold: presenter.companyModel?.ticketsSold,
                        profile: presenter.viewModel.isPrivate ? "private" : "public"
                    )
                    return presenter.useCases.saveCompanyUseCase.execute(model: model)
                        .map({ _ in imageUrl })
                        .eraseToAnyPublisher()
                } else {
                    let model = UserModel(
                        uid: FirebaseServiceImpl.shared.getCurrentUserUid()!,
                        fullname: presenter.viewModel.fullname,
                        username: presenter.viewModel.username,
                        email: presenter.userModel?.email ?? "",
                        gender: presenter.viewModel.genderType?.firebaseTitle,
                        image: imageUrl ?? presenter.userModel?.image,
                        fcm_token: presenter.userModel?.fcm_token,
                        attendingClub: presenter.userModel?.attendingClub,
                        misLigas: presenter.userModel?.misLigas,
                        profile: presenter.viewModel.isPrivate ? "private" : "public"
                    )
                    return presenter.useCases.saveUserUseCase.execute(model: model)
                        .map({ _ in imageUrl })
                        .eraseToAnyPublisher()
                }
            }
            .withUnretained(self)
            .sink { presenter, imageUrl in
                if imageUrl == nil {
                    presenter.viewModel.selectedImage = nil
                    presenter.viewModel.toast = .custom(.init(title: "Error", description: "La imagen no se pudo actualizar", image: nil))
                }
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
                AppState.shared.logOut()
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


