import SwiftUI
import Combine

enum HomeSelectedTab {
    case feed
    case map
    
    var title: String {
        switch self {
        case .feed:
            return "feed"
        case .map:
            return "mapa"
        }
    }
}


final class HomeViewModel: ObservableObject {
    @Published var selectedTab: HomeSelectedTab = .feed
    @Published var profileImageUrl: String?
    @Published var showCompanyFirstAlert: Bool = false
    @Published var showUserFirstAlert: Bool = false
    @Published var showNighoutAlert: Bool = false
    @Published var showMyProfile: Bool = false
    @Published var nighoutAlertTitle: String = ""
    @Published var nighoutAlertMessage: String = ""
    @Published var nighoutLogo: String = ""
    @Published var showGenderAlert: Bool = false
    @Published var gender: Gender?
}

protocol HomePresenter {
    var viewModel: HomeViewModel { get }
    func transform(input: HomePresenterImpl.ViewInputs)
    func isPastNinePM() -> Bool
}

final class HomePresenterImpl: HomePresenter {
    
    struct UseCases {
        let saveUserUseCase: SaveUserUseCase
    }
    
    struct Actions {
        let onOpenNotifications: VoidClosure
        let openMessages: VoidClosure
        let openHub: VoidClosure
        let openTinder: VoidClosure
    }
    
    struct ViewInputs {
        let openNotifications: AnyPublisher<Void, Never>
        let openMessages: AnyPublisher<Void, Never>
        let viewDidLoad: AnyPublisher<Void, Never>
        let updateProfileImage: AnyPublisher<Void, Never>
        let openHub: AnyPublisher<Void, Never>
        let openTinder: AnyPublisher<Void, Never>
    }
    
    struct Input {
        let openProfile: AnyPublisher<Void, Never>
    }
    
    var viewModel: HomeViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private let outinput: Input
    
    private let reloadFeedSubject: PassthroughSubject<Void, Never>
    
    private var cancellables = Set<AnyCancellable>()
    
    private var myUserModel: UserModel? = {
        UserDefaults.getUserModel()
    }()
    
    init(
        useCases: UseCases,
        actions: Actions,
        reloadFeedSubject: PassthroughSubject<Void, Never>,
        input: Input
    ) {
        self.actions = actions
        self.useCases = useCases
        self.reloadFeedSubject = reloadFeedSubject
        self.outinput = input
        
        viewModel = HomeViewModel()
    }
    
    func transform(input: HomePresenterImpl.ViewInputs) {
        viewModel
            .$gender
            .filter({ $0 != nil })
            .withUnretained(self)
            .flatMap { presenter, gender -> AnyPublisher<Bool, Never> in
                
                guard var userModel = presenter.myUserModel else {
                    return Just(false).eraseToAnyPublisher()
                }
                
                userModel.gender = gender?.firebaseTitle
                print("GENDER CHANGED")
                print(userModel.gender)
                return presenter.useCases.saveUserUseCase.execute(model: userModel)
            }
            .withUnretained(self)
            .sink { presenter, saved in
                if saved {
                    print("saved")
                } else {
                    print("not saved")
                }
            }
            .store(in: &cancellables)
        
        outinput
            .openProfile
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.viewModel.showMyProfile = true
            }
            .store(in: &cancellables)
        
        input
            .openNotifications
            .withUnretained(self)
            .sink { presenter, _ in
                self.actions.onOpenNotifications()
            }
            .store(in: &cancellables)
        
        input
            .openHub
            .withUnretained(self)
            .sink { presenter, _ in
                self.actions.openHub()
            }
            .store(in: &cancellables)
        
        input
            .openTinder
            .withUnretained(self)
            .sink { presenter, _ in
                if FirebaseServiceImpl.shared.getImUser() {
                    
#warning("TODO: this line just for testing, comment the if else below")
                    presenter.actions.openTinder()
                    

//                    if presenter.myUserModel?.social?.lowercased() == "no participando" {
//                        
//                        presenter.viewModel.showNighoutAlert = true
//                        presenter.viewModel.nighoutAlertTitle = "Social NightOut"
//                        presenter.viewModel.nighoutAlertMessage = "Eligió no participar en Social NightOut. Puede cambiar la configuración en ajustes."
//                    } else {
//                        
//                        if presenter.isPastNinePM() {
//                            presenter.actions.openTinder()
//                        } else {
//                            presenter.viewModel.showNighoutAlert = true
//                            presenter.viewModel.nighoutAlertTitle = "Social NightOut"
//                            presenter.viewModel.nighoutAlertMessage = "Social NightOut no estará disponible hasta las 21:00."
//                            
//                        }
//                    }
                   
                } else {
                    presenter.viewModel.showNighoutAlert = true
                    presenter.viewModel.nighoutAlertTitle = "Acceso Denegado"
                    presenter.viewModel.nighoutAlertMessage = "Las discotecas no tienen acceso a Social NightOut."
                }
                
            }
            .store(in: &cancellables)
        
        
        input
            .openMessages
            .withUnretained(self)
            .sink { presenter in
                self.actions.openMessages()
            }
            .store(in: &cancellables)

        input
            .viewDidLoad
            .merge(with: input.updateProfileImage)
            .withUnretained(self)
            .sink { presenter, _ in
                
                if (UserDefaults.getIsFirstLoggedIn() ?? false) && !FirebaseServiceImpl.shared.getImUser() {
                    presenter.viewModel.showCompanyFirstAlert = true
                } else if (UserDefaults.getIsFirstLoggedIn() ?? false) && FirebaseServiceImpl.shared.getImUser() {
                    presenter.viewModel.showUserFirstAlert = true
                }
                
                UserDefaults.setIsFirstLoggedIn(false)
                
                let imUser = FirebaseServiceImpl.shared.getImUser()
                if imUser {
                    presenter.viewModel.profileImageUrl = UserDefaults.getUserModel()?.image
//                    if presenter.myUserModel?.gender == nil, presenter.myUserModel?.gender?.isEmpty ?? true {
//                        presenter.viewModel.showGenderAlert = true
//                    }
                } else {
                    presenter.viewModel.profileImageUrl =  UserDefaults.getCompanyUserModel()?.imageUrl
                }
                
                presenter.reloadFeedSubject.send()
            }
            .store(in: &cancellables)
    }
    
    func isPastNinePM() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Extraemos la hora y los minutos de la fecha actual
        let components = calendar.dateComponents([.hour, .minute], from: now)
        
        // Comparamos si es 21:00 (9 PM) o más tarde
        if let hour = components.hour, let minute = components.minute {
            return hour > 21 || (hour == 21 && minute >= 0)
        }
        
        return false
    }

}
