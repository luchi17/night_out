import SwiftUI
import Combine

final class MyUserCompanySettingsViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    
    @Published var locationString = ""
    @Published var endTime: String = ""
    @Published var startTime: String = ""
    @Published var selectedTag: LocationSelectedTag = .none
    
    @Published var dismiss: Bool = false
    
    // Formatear la fecha en una cadena de hora:minuto
    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

protocol MyUserCompanySettingsPresenter {
    var viewModel: MyUserCompanySettingsViewModel { get }
    func transform(input: MyUserCompanySettingsPresenterImpl.ViewInputs)
}

final class MyUserCompanySettingsPresenterImpl: MyUserCompanySettingsPresenter {
    
    struct UseCases {
        let saveCompanyDataUseCase: SaveCompanyUseCase
    }
   
    struct Actions { }
    
    struct ViewInputs {
        let viewDidLoad: AnyPublisher<Void, Never>
        let saveInfo: AnyPublisher<Void, Never>
    }
    
    var viewModel: MyUserCompanySettingsViewModel
    
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(
        useCases: UseCases,
        actions: Actions
    ) {
        self.actions = actions
        self.useCases = useCases
        self.viewModel = MyUserCompanySettingsViewModel()
        
    }
    
    func transform(input: MyUserCompanySettingsPresenterImpl.ViewInputs) {
        
        let companyModel = UserDefaults.getCompanyUserModel()
        
        input
            .viewDidLoad
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.viewModel.startTime = companyModel?.startTime ?? ""
                presenter.viewModel.endTime = companyModel?.endTime ?? ""
                presenter.viewModel.selectedTag = LocationSelectedTag(rawValue: companyModel?.selectedTag) ?? .none
                presenter.viewModel.locationString = companyModel?.location ?? "Selecciona Ubicación"
            }
            .store(in: &cancellables)
        
        input
            .saveInfo
            .withUnretained(self)
            .flatMap { presenter, _ in
                let model = CompanyModel(
                    email: companyModel?.email,
                    endTime: presenter.viewModel.endTime,
                    selectedTag: presenter.viewModel.selectedTag == .none ? "Etiqueta" : presenter.viewModel.selectedTag.title,
                    fullname: companyModel?.fullname,
                    username: companyModel?.username,
                    imageUrl: companyModel?.imageUrl,
                    location: presenter.viewModel.locationString,
                    startTime: presenter.viewModel.startTime,
                    uid: FirebaseServiceImpl.shared.getCurrentUserUid()!,
                    entradas: companyModel?.entradas,
                    payment: companyModel?.payment,
                    ticketsSold: companyModel?.ticketsSold,
                    profile: companyModel?.profile
                )
                return presenter.useCases.saveCompanyDataUseCase.execute(model: model)
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .sink { presenter, saved in
                presenter.viewModel.dismiss = true
            }
            .store(in: &cancellables)
        
       

      
    }
}


