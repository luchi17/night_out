import Combine
import SwiftUI
import Firebase
import CoreLocation

struct Entrada: Identifiable, Equatable {
    let id = UUID()
    let type: String
    let price: Double
    let description: String
    let capacity: String
    
    init(type: String, price: Double, description: String, capacity: String) {
        self.type = type
        self.price = price
        self.description = description
        self.capacity = capacity
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Entrada, rhs: Entrada) -> Bool {
        return lhs.id == rhs.id
    }
}

class TicketDetailViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var companyModel: CompanyModel
    @Published var fiesta: Fiesta
    @Published var entradas: [Entrada] = []
    
    @Published var entradaTapped: Entrada?
    @Published var quantity = 1
    
    @Published var finalPrice: Double = 0.0
    
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
        let pagar: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
    }
    
    struct Actions {
        let goBack: VoidClosure
        let onOpenMaps: InputClosure<(Double, Double)>
        let onOpenAppleMaps: InputClosure<(CLLocationCoordinate2D, String?)>
        let openTicketInfoPay: InputClosure<PayDetailModel>
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
            .pagar
            .withUnretained(self)
            .sink { presenter, _ in
                guard let entradaTapped = presenter.viewModel.entradaTapped else { return }
                
                Task {
                    await presenter.doReservation(entrada: entradaTapped)
                }
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
                
                let formattedPrice: Double = {
                    if let priceString = eventInfo["price"] as? String {
                        
                        return self.formatPrice(priceString) ?? 0.0
                    }
                    
                    return 0.0
                }()
               
                let description = eventInfo["description"] as? String ?? "Sin descripción"
                let capacity = eventInfo["capacity"] as? String ?? "0"

                print("🎟 Entrada encontrada: $\(typeName) | 💰 Precio: $\(formattedPrice) | 🎟 Capacidad: \(capacity)")
                
                let entrada = Entrada(
                    type: typeName,
                    price: formattedPrice,
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
    
    func formatPrice(_ priceString: String) -> Double? {
        if let priceDouble = Double(priceString) {
            // Verificamos si el número tiene decimales distintos de 0
            if priceDouble.truncatingRemainder(dividingBy: 1) == 0 {
                return Double(Int(priceDouble)) // Devuelve un Int convertido a Double (sin decimales)
            } else {
                return Double(String(format: "%.2f", priceDouble)) ?? priceDouble // Devuelve con 2 decimales
            }
        }
        return nil // Si la conversión falla, retorna nil
    }
    
    private func doReservation(entrada: Entrada) async {
        
        guard let userUID = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let eventRef = FirebaseServiceImpl.shared
            .getCompanies()
            .child(viewModel.companyModel.uid)
            .child("Entradas")
            .child(viewModel.fiesta.fecha)
            .child(viewModel.fiesta.name)
            .child("types")
            .child(entrada.type)
        
        print("🔄 Iniciando la reserva de capacidad en Firebase")
        print("🔄 \(viewModel.fiesta.fecha)/////////////\(viewModel.fiesta.name)////////////\(entrada.type)")
        
        do {
            
            try await eventRef.runTransactionBlock { [weak self] (currentData) -> TransactionResult in
                
                guard let self = self else { return .success(withValue: currentData) }
                
                guard var eventData = currentData.value as? [String: Any] else {
                    return .success(withValue: currentData)
                }
                
                guard let currentCapacityStr = eventData["capacity"] as? String,
                      let currentCapacity = Int(currentCapacityStr) else {
                    print("No se puedo obtener la capacidad")
                    return .abort()
                }
                
                let reservedTickets = self.viewModel.quantity
                
                if currentCapacity >= reservedTickets {
                    let newCapacity = currentCapacity - reservedTickets
                    eventData["capacity"] = "\(newCapacity)" // Guardar como String
                    
                    // Crear variable temporal
                    var tempEventData = eventData
                    
                    // Verifica si "Reservations" existe, si no, créalo
                    if var reservations = tempEventData["Reservations"] as? [String: Any] {
                        // Verifica si el usuario ya tiene datos en "Reservations"
                        if var userReservations = reservations[userUID] as? [String: Any] {
                            userReservations["reserved"] = reservedTickets
                            reservations[userUID] = userReservations
                        } else {
                            // Si no existe, crea la estructura para el usuario
                            reservations[userUID] = ["reserved": reservedTickets]
                        }
                        tempEventData["Reservations"] = reservations
                    } else {
                        // Si "Reservations" no existe, crea toda la estructura
                        tempEventData["Reservations"] = [userUID: ["reserved": reservedTickets]]
                    }
                    
                    
                    print("add reservation info")
                    print(tempEventData)
                    currentData.value = tempEventData

                    print("✅ Capacidad = \(currentCapacity)")
                    print("✅ Antigua capacidad: \(currentCapacityStr); Nueva capacidad = \(newCapacity)")
                } else {
                    print("❌ No hay entradas reservadas para restaurar")
                }
                
                print("IR A DETALLE")
                let model = PayDetailModel(
                    fiesta: self.viewModel.fiesta,
                    quantity: self.viewModel.quantity,
                    price: self.viewModel.finalPrice,
                    entrada: entrada,
                    companyUid: self.viewModel.companyModel.uid
                )
                DispatchQueue.main.async {
                    self.actions.openTicketInfoPay(model)
                }
               
                return .success(withValue: currentData)
                
            }
        } catch {
            print("❌ Error en la transacción: \(error.localizedDescription)")
        }
    }
}
