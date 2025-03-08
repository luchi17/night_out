import Combine
import SwiftUI
import Firebase
import CoreLocation

struct Entrada: Identifiable {
    let id = UUID()
    let type: String
    let price: String
    let description: String
    let capacity: String
    
    init(type: String, price: String, description: String, capacity: String) {
        self.type = type
        self.price = price
        self.description = description
        self.capacity = capacity
    }
}

class TicketDetailViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var companyModel: CompanyModel
    @Published var fiesta: Fiesta
    @Published var entradas: [Entrada] = []
    
    init(companyModel: CompanyModel, fiesta: Fiesta) {
        self.companyModel = companyModel
        self.fiesta = fiesta
    }
}

protocol TicketDetailPresenter {
    var viewModel: TicketDetailViewModel { get }
    func transform(input: TicketDetailPresenterImpl.Input)
}

final class TicketDetailPresenterImpl: TicketDetailPresenter {
    var viewModel: TicketDetailViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
        let openMaps: AnyPublisher<Void, Never>
        let openAppleMaps: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
    }
    
    struct Actions {
        let goBack: VoidClosure
        let onOpenMaps: InputClosure<(Double, Double)>
        let onOpenAppleMaps: InputClosure<(CLLocationCoordinate2D, String?)>
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases, companyModel: CompanyModel, fiesta: Fiesta) {
        
        self.viewModel = TicketDetailViewModel(
            companyModel: companyModel,
            fiesta: fiesta
        )
        self.actions = actions
        self.useCases = useCases
    }
    
    func transform(input: Input) {
        
        input
            .viewIsLoaded
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.viewModel.loading = true
                presenter.getEntradasPorEvento()
            }
            .store(in: &cancellables)

        input
            .goBack
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goBack()
            }
            .store(in: &cancellables)
        
        input
            .openMaps
            .withUnretained(self)
            .sink { presenter, _ in

                if let location = presenter.viewModel.companyModel.location,
                   let coordinate = LocationManager.shared.getCoordinatesFromString(location) {
                    
                    presenter.actions.onOpenMaps((coordinate.latitude, coordinate.longitude))
                }
            }
            .store(in: &cancellables)
        
        input
            .openAppleMaps
            .withUnretained(self)
            .sink { presenter, _ in
                
                if let location = presenter.viewModel.companyModel.location,
                   let coordinate = LocationManager.shared.getCoordinatesFromString(location) {
                    
                    presenter.actions.onOpenAppleMaps((coordinate: coordinate, placeName: presenter.viewModel.companyModel.username))
                }
            }
            .store(in: &cancellables)
    }
    
    private func getEntradasPorEvento() {
        
        let typesRef = FirebaseServiceImpl.shared.getCompanies()
            .child(viewModel.companyModel.uid)
            .child("Entradas")
            .child(viewModel.fiesta.fecha)
            .child(viewModel.fiesta.name)
            .child("types")
        
        typesRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            if !snapshot.exists() {
                self.viewModel.toast = .custom(.init(title: "Error", description: "No se encontraron entradas para este evento.", image: nil))
                return
            }
                
            self.viewModel.entradas.removeAll()
            
            for typeSnapshot in snapshot.children {
                
                guard let typeData = typeSnapshot as? DataSnapshot else {
                    continue
                }
             
                let typeName = typeData.key
                let eventInfo = typeData.value as? [String: Any] ?? [:]
                
                let price = eventInfo["price"] as? String ?? "Desconocido"
                let description = eventInfo["description"] as? String ?? "Sin descripción"
                let capacity = eventInfo["capacity"] as? String ?? "0"

                print("🎟 Entrada encontrada: $\(typeName) | 💰 Precio: $\(price) | 🎟 Capacidad: \(capacity)")
                
                let entrada = Entrada(
                    type: typeName,
                    price: price,
                    description: description,
                    capacity: capacity
                )
                self.viewModel.entradas.append(entrada)
                
            }
            DispatchQueue.main.async {
                self.viewModel.loading = false
            }
        }
    }
}
