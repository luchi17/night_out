import Combine
import SwiftUI
import Firebase

class DiscotecaDetailViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var companyModel: CompanyModel
    @Published var following: FollowButtonType = .follow
    @Published var fiestas: [Fiesta]
    
    init(companyModel: CompanyModel, fiestas: [Fiesta]) {
        self.companyModel = companyModel
        self.fiestas = fiestas
    }
}

protocol DiscotecaDetailPresenter {
    var viewModel: DiscotecaDetailViewModel { get }
    func transform(input: DiscotecaDetailPresenterImpl.Input)
}

final class DiscotecaDetailPresenterImpl: DiscotecaDetailPresenter {
    var viewModel: DiscotecaDetailViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
        let followTapped: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
        let goToEvent: AnyPublisher<Fiesta, Never>
    }
    
    struct UseCases {
        let followUseCase: FollowUseCase
    }
    
    struct Actions {
        let goBack: VoidClosure
        let goToEvent: InputClosure<(CompanyModel, Fiesta)>
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases, companyModel: CompanyModel, fiestas: [Fiesta]) {
        
        self.viewModel = DiscotecaDetailViewModel(
            companyModel: companyModel,
            fiestas: fiestas
        )
        self.actions = actions
        self.useCases = useCases
    }
    
    func transform(input: Input) {
        
        
        input
            .viewIsLoaded
            .filter({ self.viewModel.fiestas.isEmpty })
            .withUnretained(self)
            .sink { presenter, _  in
                presenter.viewModel.loading = true
                presenter.loadEvents()
            }
            .store(in: &cancellables)
        
        input
            .viewIsLoaded
            .withUnretained(self)
            .flatMap({ presenter, _ -> AnyPublisher<FollowModel?, Never> in
                guard let currentUId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
                    return Just(nil).eraseToAnyPublisher()
                }
                return presenter.useCases.followUseCase.fetchFollow(id: currentUId)
            })
            .withUnretained(self)
            .sink { presenter, followModel in
                
                let followingCompany = followModel?.following?.keys.contains(presenter.viewModel.companyModel.uid) ?? false
                presenter.viewModel.following = followingCompany ? .following : .follow
            }
            .store(in: &cancellables)
        
        input
            .followTapped
            .withUnretained(self)
            .sink { presenter, followModel in
                presenter.followButtonTapped()
            }
            .store(in: &cancellables)
        
        input
            .goToEvent
            .withUnretained(self)
            .sink { presenter, fiesta in
                presenter.actions.goToEvent((self.viewModel.companyModel, fiesta))
            }
            .store(in: &cancellables)

        input
            .goBack
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goBack()
            }
            .store(in: &cancellables)
    }
    
    private func followButtonTapped() {
        guard let currentUId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            return
        }
        switch viewModel.following {
        case .follow:
            // Añadir al seguimiento en "Follow"
            useCases.followUseCase.addFollow(
                requesterProfileUid: currentUId,
                profileUid: viewModel.companyModel.uid,
                needRemoveFromPending: false
            )
            .withUnretained(self)
            .sink { presenter, followOk in
                if followOk {
                    print("started following \(presenter.viewModel.companyModel.uid)")
                    presenter.viewModel.following = .following
                } else {
                    print("Error: started following \(presenter.viewModel.companyModel.uid)")
                }
            }
            .store(in: &cancellables)
            
        case .following:
            // Eliminar del seguimiento en "Follow"
            useCases.followUseCase.removeFollow(
                requesterProfileUid: currentUId,
                profileUid: viewModel.companyModel.uid
            )
            .withUnretained(self)
            .sink { presenter, unfollowOk in
                if unfollowOk {
                    print("remove following \(presenter.viewModel.companyModel.uid)")
                    presenter.viewModel.following = .follow
                } else {
                    print("Error: removing following \(presenter.viewModel.companyModel.uid)")
                }
            }
            .store(in: &cancellables)
        }
    }
    
    
    func loadEvents() {
        
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 * 1000 // Timestamp de hoy a las 00:00h
        
        FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: viewModel.companyModel.uid).observeSingleEvent(of: .value) { [weak self] companySnapshot in
            
            guard let self = self else { return }
            
            self.viewModel.fiestas.removeAll()
            
            var tempEvents: [Fiesta] = []
            
            for dateSnapshot in companySnapshot.childSnapshot(forPath: "Entradas").children {
                
                guard let dateData = dateSnapshot as? DataSnapshot else {
                    return
                }
                
                let fecha = dateData.key
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy"
                
                if let eventDate = dateFormatter.date(from: fecha), eventDate.timeIntervalSince1970 * 1000 >= today {
                    
                    for eventSnapshot in dateData.children {
                        
                        guard let eventData = eventSnapshot as? DataSnapshot else {
                            return
                        }
                        
                        let eventName = eventData.key
                        let eventInfo = eventData.value as? [String: Any] ?? [:]
                        
                        let imageUrl = eventInfo["image_url"] as? String ?? ""
                        let description = eventInfo["description"] as? String ?? "Sin descripción"
                        let startTime = eventInfo["start_time"] as? String ?? "No disponible"
                        let endTime = eventInfo["end_time"] as? String ?? "No disponible"
                        let musicGenre = eventInfo["musica"] as? String ?? "No especificado"
                        
                        let fiesta = Fiesta(
                            name: eventName,
                            fecha: fecha,
                            imageUrl: imageUrl,
                            description: description,
                            startTime: startTime,
                            endTime: endTime,
                            musicGenre: musicGenre
                        )
                        
                        tempEvents.append(fiesta)
                    }
                    
                }
            }
            
            DispatchQueue.main.async {
                self.viewModel.loading = false
                self.viewModel.fiestas = tempEvents
            }
        }
    }
}
