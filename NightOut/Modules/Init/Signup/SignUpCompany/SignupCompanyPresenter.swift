import SwiftUI
import Combine
import FirebaseAuth
import CoreLocation
import PhotosUI

enum LocationSelectedTag {
    case sportCasual
    case informal
    case semiInformal
    case none
    
    init?(rawValue: String?) {
        guard let rawValue = rawValue else {
            self = .none
            return
        }
        if rawValue == LocationSelectedTag.sportCasual.title {
            self = .sportCasual
        }
        else if rawValue == LocationSelectedTag.informal.title {
            self = .informal
        }
        else if rawValue == LocationSelectedTag.semiInformal.title {
            self = .semiInformal
        }
        else {
            self = .none
        }
        
    }
    
    var title: String {
        switch self {
        case .sportCasual:
            return "Sport-Casual"
        case .informal:
            return "Informal"
        case .semiInformal:
            return "Semi-informal"
        case .none:
            return "VESTIMENTA"
        }
    }
}

final class SignupCompanyViewModel: ObservableObject {
    
    @Published var userName: String = ""
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var endTime: String = ""
    @Published var startTime: String = ""
    @Published var fcmToken: String = ""
    @Published var selectedTag: LocationSelectedTag = .none
    @Published var imageData: Data? = nil
    @Published var locationString = ""
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    @Published var selectedImage: UIImage?
    
    @Published var openPicker: Bool = false
    @Published var showPermissionAlert: Bool = false
    
    @Published var selectedItem: PhotosPickerItem?
    
    var imageUrl: String?
    
    init() {
        
    }
    
    // Formatear la fecha en una cadena de hora:minuto
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
}

protocol SignupCompanyPresenter {
    var viewModel: SignupCompanyViewModel { get }
    func transform(input: SignupCompanyPresenterImpl.ViewInputs)
}

final class SignupCompanyPresenterImpl: SignupCompanyPresenter {
    
    struct UseCases {
        let signupUseCase: SignupUseCase
        let saveCompanyUseCase: SaveCompanyUseCase
    }
    
    struct Actions {
        var goToTabView: VoidClosure
        var backToLogin: VoidClosure
    }
    
    struct ViewInputs {
        let signupCompany: AnyPublisher<Void, Never>
        let login: AnyPublisher<Void, Never>
        let openPicker: AnyPublisher<Void, Never>
    }
    
    var viewModel: SignupCompanyViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        
        viewModel = SignupCompanyViewModel()
    }
    
    func transform(input: SignupCompanyPresenterImpl.ViewInputs) {
        
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
            .login
            .withUnretained(self)
            .sink { presenter, _ in
                self.actions.backToLogin()
            }
            .store(in: &cancellables)
        
        signupListener(input: input)
    }
    
    func signupListener(input: SignupCompanyPresenterImpl.ViewInputs) {
        let signuppublisher =
        input
            .signupCompany
            .withUnretained(self)
            .performRequest(request: { presenter, _ in
                return presenter.useCases.signupUseCase.executeCompany(
                    email: self.viewModel.email,
                    password: self.viewModel.password
                )
                .eraseToAnyPublisher()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error != nil {
                    self.viewModel.toast = .custom(.init(title: "Error", description: error?.localizedDescription, image: nil))
                }
            })
           
        let saveImagePublisher = signuppublisher
            .withUnretained(self)
            .performRequest(request: { presenter, fcmToken -> AnyPublisher<(String?, String), Never> in
                guard let imageData = presenter.viewModel.imageData else {
                    return Just((nil, fcmToken))
                        .eraseToAnyPublisher()
                }
                return presenter.useCases.saveCompanyUseCase.executeGetImageUrl(imageData: imageData)
                    .map({ ($0, fcmToken)})
                    .eraseToAnyPublisher()
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { _ in  })
            .handleEvents(receiveOutput: { [weak self] data in
                if let imageUrl = data.0 {
                    self?.viewModel.imageUrl = imageUrl
                } else {
                    print("Image url no se ha podido obtener")
                }
                
                self?.viewModel.fcmToken = data.1
                
            })
            .eraseToAnyPublisher()
        
        saveImagePublisher
            .withUnretained(self)
            .performRequest(request: { presenter, imageUrl -> AnyPublisher<(Bool, CompanyModel?), Never> in
                guard let uid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just((false, nil))
                        .eraseToAnyPublisher()
                }
                let startTime = presenter.viewModel.startTime.isEmpty ? presenter.timeString(from: Date()) : presenter.viewModel.startTime
                
                let endTime = presenter.viewModel.endTime.isEmpty ? presenter.timeString(from: Date()) : presenter.viewModel.endTime
       
                let model = CompanyModel(
                    email: presenter.viewModel.email.lowercased(),
                    endTime: endTime,
                    selectedTag: presenter.viewModel.selectedTag == .none ? "Etiqueta" : presenter.viewModel.selectedTag.title,
                    fullname: presenter.viewModel.fullName,
                    username: presenter.viewModel.userName.lowercased(),
                    imageUrl: presenter.viewModel.imageUrl,
                    location: presenter.viewModel.locationString,
                    startTime: startTime,
                    uid: uid,
                    fcm_token: presenter.viewModel.fcmToken
                )
                return presenter.useCases.saveCompanyUseCase.execute(model: model)
                    .map({ ($0, model)})
                    .eraseToAnyPublisher()
                   
            }, loadingClosure: { [weak self] loading in
                guard let self = self else { return }
                self.viewModel.loading = loading
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if error != nil {
                    self.viewModel.toast = .custom(.init(title: "Error", description: error?.localizedDescription, image: nil))
                }
            })
            .withUnretained(self)
            .flatMap({ presenter, data in
                presenter.useCases.saveCompanyUseCase.executeTerms()
                    .map({ _ in data })
                    .eraseToAnyPublisher()
            })
            .sink(receiveValue: { [weak self] data in
                self?.viewModel.loading = false
                if data.0, let model = data.1 {
                    UserDefaults.setIsFirstLoggedIn(true)
                    UserDefaults.setCompanyUserModel(model)
                    self?.actions.goToTabView()
                } else {
                    self?.viewModel.toast = .custom(.init(title: "Error", description: "Could not save company", image: nil))
                }
               
            })
            .store(in: &cancellables)
    }
    
    // Formatear la fecha en una cadena de hora:minuto
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
