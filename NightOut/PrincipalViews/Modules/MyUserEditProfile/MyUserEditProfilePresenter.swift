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
    
    init(profileImageUrl: String?, username: String?, fullname: String?, gender: Gender?, profile: ProfileType) {
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
    }
    
    struct Actions {
        let backToLogin: VoidClosure
    }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let goToLogin: AnyPublisher<Void, Never>
        let saveInfo: AnyPublisher<Void, Never>
    }
    
    var viewModel: MyUserEditProfileViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private var userModel: UserModel?
    
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
                presenter.userModel = UserDefaults.getUserModel()
                presenter.viewModel = MyUserEditProfileViewModel(
                    profileImageUrl: presenter.userModel?.image,
                    username: presenter.userModel?.username,
                    fullname: presenter.userModel?.fullname,
                    gender: presenter.userModel?.genderType,
                    profile: presenter.userModel?.profileType ?? .publicProfile
                )
            }
            .store(in: &cancellables)

        input
            .goToLogin
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.backToLogin()
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
            .withUnretained(self)
            .sink { presenter, imageUrl in
                if imageUrl == nil {
                    presenter.viewModel.selectedImage = nil
                    presenter.viewModel.toast = .custom(.init(title: "Error", description: "La imagen no se pudo actualizar", image: nil))
                }
            }
            .store(in: &cancellables)
        
    }
}


