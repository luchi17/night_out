import SwiftUI
import Combine
import PhotosUI

final class MyUserEditProfileViewModel: ObservableObject {
    @Published var profileImageUrl: String?
    @Published var username: String = ""
    @Published var fullname: String = ""
    @Published var genderType: Gender?
    @Published var isPrivate: Bool = false
    @Published var participate: Bool = false
    @Published var imageData: Data? = nil
    @Published var selectedImage: UIImage?
    
    @Published var toast: ToastType?
    @Published var shouldCloseSheet: Bool = false
    @Published var loading: Bool = false
    @Published var showAlertMessage: Bool = false
    @Published var alertMessage: String = ""
    @Published var progressMessage: String = ""
    @Published var showProgress: Bool = false
    
    @Published var openPicker: Bool = false
    @Published var showPermissionAlert: Bool = false
    @Published var selectedItem: PhotosPickerItem?
    
    init(profileImageUrl: String?, username: String?, fullname: String?, gender: Gender?, profile: ProfileType?, participate: String? = nil) {
        self.profileImageUrl = profileImageUrl
        self.username = username ?? "Username no disponible"
        self.fullname = fullname ?? "Fullname no disponible"
        self.genderType = gender
        self.isPrivate = profile == .privateProfile
        self.participate = participate == "participando"
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
        let openPicker: AnyPublisher<Void, Never>
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
        
        viewModel.progressMessage = "Please wait, we are deleting your account..."
    }
    
    func transform(input: MyUserEditProfilePresenterImpl.ViewInputs) {
        
        input
            .openPicker
            .withUnretained(self)
            .sink { presenter, _ in
                GalleryManager.shared.checkPermissionsAndOpenPicker() { hasPermission in
                    presenter.viewModel.openPicker = hasPermission
                    presenter.viewModel.showPermissionAlert = !hasPermission
                }
            }
            .store(in: &cancellables)
        
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                if FirebaseServiceImpl.shared.getImUser() {
                    presenter.userModel = UserDefaults.getUserModel()
                    presenter.viewModel.profileImageUrl = presenter.userModel?.image
                    presenter.viewModel.username = presenter.userModel?.username ?? "No disponible"
                    presenter.viewModel.fullname = presenter.userModel?.fullname ?? "No disponible"
                    presenter.viewModel.genderType = presenter.userModel?.genderType
                    presenter.viewModel.isPrivate = presenter.userModel?.profileType == .privateProfile
                    presenter.viewModel.participate = presenter.userModel?.social == "participando"
                    
                } else {
                    presenter.companyModel = UserDefaults.getCompanyUserModel()
                    presenter.viewModel.profileImageUrl = presenter.companyModel?.imageUrl
                    presenter.viewModel.username = presenter.companyModel?.username ?? "No disponible"
                    presenter.viewModel.fullname = presenter.companyModel?.fullname ?? "No disponible"
                    presenter.viewModel.genderType = nil
                    presenter.viewModel.isPrivate = presenter.userModel?.profileType == .privateProfile
                }
            }
            .store(in: &cancellables)
        
        input
            .saveInfo
            .withUnretained(self)
            .flatMap { presenter, _ -> AnyPublisher<String?, Never> in
                guard let imageData = presenter.viewModel.imageData else {
                    if !FirebaseServiceImpl.shared.getImUser() {
                        return Just(presenter.companyModel?.imageUrl ?? "")
                            .eraseToAnyPublisher()
                    } else {
                        return Just(presenter.userModel?.image ?? "")
                            .eraseToAnyPublisher()
                    }
                }
                return presenter.useCases.saveCompanyUseCase.executeGetImageUrl(imageData: imageData)
                    .handleEvents(receiveRequest: { [weak self] _ in
                        self?.viewModel.loading = true
                    })
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
                        profile: presenter.viewModel.isPrivate ? "private" : "public",
                        MisEntradas: presenter.companyModel?.MisEntradas
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
                        profile: presenter.viewModel.isPrivate ? "private" : "public",
                        Liked: presenter.userModel?.Liked,
                        social: presenter.viewModel.participate ? "participando" : "no participando",
                        misCopas: presenter.userModel?.MisCopas ?? 0,
                        misEntradas: presenter.userModel?.MisEntradas,
                        paymentMethods: presenter.userModel?.PaymentMethods
                    )
                    return presenter.useCases.saveUserUseCase.execute(model: model)
                        .map({ _ in imageUrl })
                        .eraseToAnyPublisher()
                }
            }
            .withUnretained(self)
            .sink { presenter, imageUrl in
                presenter.viewModel.loading = false
                if imageUrl == nil {
                    presenter.viewModel.selectedImage = nil
                    presenter.viewModel.toast = .custom(.init(title: "Error", description: "La imagen no se pudo actualizar", image: nil))
                } else {
                    presenter.viewModel.toast = .success(.init(title: "", description: "Información actualizada.", image: nil))
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


