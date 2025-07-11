import Combine
import SwiftUI
import Firebase
import CoreLocation

struct PayDetailModel: Identifiable, Equatable {
    let fiesta: Fiesta
    let quantity: Int
    let price: Double
    let entrada: Entrada
    let companyUid: String
    let id = UUID()
    
    init(fiesta: Fiesta, quantity: Int, price: Double, entrada: Entrada, companyUid: String) {
        self.fiesta = fiesta
        self.quantity = quantity
        self.price = price
        self.entrada = entrada
        self.companyUid = companyUid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PayDetailModel, rhs: PayDetailModel) -> Bool {
        return lhs.id == rhs.id
    }
}

class PayDetailViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var model: PayDetailModel
    @Published var gastosGestion: Double = 0.0
    @Published var finalPrice: Double = 0.0
    
    @Published var countdownText: String = ""
    
    @Published var timeRemaining = 300 // 5 minutos en segundos
    @Published var timerIsRunning = false
    @Published var showingToastExpired = false
    
    
    @Published var users: [UserViewTicketModel] = []
    
    init(model: PayDetailModel) {
        self.model = model
    }
}

protocol PayDetailPresenter {
    var viewModel: PayDetailViewModel { get }
    func transform(input: PayDetailPresenterImpl.Input)
}

final class PayDetailPresenterImpl: PayDetailPresenter {
    var viewModel: PayDetailViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
        let goBackFromExpired: AnyPublisher<Void, Never>
        let pagar: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
        
    }
    
    struct Actions {
        let goBack: VoidClosure
        let openPDFPay: InputClosure<PDFModel>
        let navigateToHome: VoidClosure
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    var countDownTimer: Timer?

    private let eventRef: DatabaseReference
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases, model: PayDetailModel) {
        
        self.viewModel = PayDetailViewModel(model: model)
        self.actions = actions
        self.useCases = useCases
        
        self.eventRef = FirebaseServiceImpl.shared
            .getCompanies()
            .child(viewModel.model.companyUid)
            .child("Entradas")
            .child(viewModel.model.fiesta.fecha)
            .child(viewModel.model.fiesta.name)
            .child("types")
            .child(viewModel.model.entrada.type)
        
        self.startTimer()
    }
    
    func transform(input: Input) {
        
        input
            .viewIsLoaded
            .withUnretained(self)
            .sink { presenter, _ in
                
                //Adding personal cards
                for _ in 0..<presenter.viewModel.model.quantity {
                    presenter.viewModel.users.append(UserViewTicketModel.empty())
                }
                
                let managementFee = 1.0 * Double(presenter.viewModel.model.quantity)
                presenter.viewModel.gastosGestion = managementFee
                presenter.viewModel.finalPrice = presenter.totalPrice()
            }
            .store(in: &cancellables)
        
        input
            .goBackFromExpired
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.navigateToHome()
            }
            .store(in: &cancellables)
        
        input
            .goBack
            .withUnretained(self)
            .sink { presenter, _ in
                
                if presenter.viewModel.timerIsRunning {
                    Task {
                        await presenter.restoreCapacity()
                    }
                    print("stopping timer")
                    presenter.stopTimer()
                    
                }
            }
            .store(in: &cancellables)
        
        
        input
            .pagar
            .withUnretained(self)
            .sink { presenter, _ in
                Task {
                    await presenter.confirmPurchase()
                }
            }
            .store(in: &cancellables)
        
    }
    
    // Inicia el temporizador
    func startTimer() {
        if !viewModel.timerIsRunning {
            viewModel.timerIsRunning = true
            countDownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.viewModel.timeRemaining > 0 {
                    
                    self.viewModel.timeRemaining -= 1
                    
                    self.viewModel.countdownText = "Tiempo restante: \(timeFormatted(self.viewModel.timeRemaining))"
                    
                } else {
                    self.stopTimer()
                    
                    print( "❌ Tiempo expirado. Cancelando reserva y restaurando aforo en Firebase.")

                   
                    Task {
                        await self.restoreCapacity()
                    }
                    
                    DispatchQueue.main.async {
                        self.viewModel.showingToastExpired = true
                        self.viewModel.toast = .custom(.init(title: "El tiempo ha expirado.", description: "Vuelve atrás para empezar la reserva de entradas.", image: nil))
                    }
                }
            }
        }
    }
    
    // Detiene el temporizador
    func stopTimer() {
        countDownTimer?.invalidate()
        viewModel.timerIsRunning = false
    }
    
    func timeFormatted(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    
    private func restoreCapacity() async {
        
        print("restoreCapacity")
        print("🔄 Iniciando restauración de capacidad en Firebase")
        print("🔄 \(viewModel.model.fiesta.fecha)/////////////\(viewModel.model.fiesta.name)////////////\(viewModel.model.entrada.type)")
        
        guard let userUID = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        do {
            
            try await eventRef.runTransactionBlock { [weak self] (currentData) -> TransactionResult in
                
                guard let self = self else { return .success(withValue: currentData) }
                
                guard var eventData = currentData.value as? [String: Any] else {
                    return .success(withValue: currentData)
                }
                
                guard let currentCapacityStr = eventData["capacity"] as? String,
                      let currentCapacity = Int(currentCapacityStr) else {
                    print("No se puedo obtener la capacidad")
                    return .success(withValue: currentData)
                }
                
                let reservedTickets = self.viewModel.model.quantity
                
                if reservedTickets > 0 {
                    let newCapacity = currentCapacity + reservedTickets
                    eventData["capacity"] = "\(newCapacity)" // Guardar como String
                    
                    if var reservations = eventData["Reservations"] as? [String: Any] {
                        
                        reservations[userUID] = nil
                        
                        // Si después de eliminar no quedan reservas, eliminamos toda la clave "Reservations"
                            if reservations.isEmpty {
                                eventData["Reservations"] = nil
                            } else {
                                eventData["Reservations"] = reservations
                            }
                        
                    }
                    
                    currentData.value = eventData
                    
                    print("remove reservation info")
                    print(eventData)
                    
                    print("✅ Capacidad = \(currentCapacity)")
                    print("✅ Antigua capacidad: \(currentCapacityStr); Nueva capacidad = \(newCapacity)")
                } else {
                    print("❌ No hay entradas reservadas para restaurar")
                }
                
                return .success(withValue: currentData)
                
            }
        } catch {
            print("❌ Error en la transacción: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func confirmPurchase() async {
        
        print("confirmPurchase")
        countDownTimer?.invalidate() // Detiene el temporizador
        
        guard let userUID = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
  
        do {
            // Ejecutamos la transacción usando async/await
            
            try await eventRef.runTransactionBlock { (currentData) -> TransactionResult in
                
                guard var eventData = currentData.value as? [String: Any] else {
                    return .success(withValue: currentData) // Si no hay valor, no se hace nada
                }
                
                guard let currentCapacityStr = eventData["capacity"] as? String,
                      let currentCapacity = Int(currentCapacityStr) else {
                    return .success(withValue: currentData)
                }
                
                let reservations = eventData["Reservations"] as? [String: Any]
                let userReservation = reservations?[userUID] as?  [String: Any]
                let reserved = userReservation?["reserved"] as? Int ?? 0
                
                
                if reserved > 0 && currentCapacity >= reserved {
                    eventData["capacity"] = currentCapacityStr // ✅ La reducción ya se hizo al reservar
                    // ✅ Eliminar reserva
                    
                    if var reservations = eventData["Reservations"] as? [String: Any] {
                        
                        reservations[userUID] = nil
                        
                        // Si después de eliminar no quedan reservas, eliminamos toda la clave "Reservations"
                            if reservations.isEmpty {
                                eventData["Reservations"] = nil
                            } else {
                                eventData["Reservations"] = reservations
                            }
                    }
                    
                    currentData.value = eventData
                    return .success(withValue: currentData)
                } else {
                    return .abort()
                }
            }
            
            // Continuamos con la lógica una vez que la transacción ha sido completada exitosamente
            var personDataList: [PersonTicketData] = []
            var hasErrors = false
            
            for (index, user) in viewModel.users.enumerated() {
                
                if user.name.isEmpty || user.email.isEmpty || user.confirmEmail.isEmpty || user.birthDate.isEmpty {
                    self.viewModel.toast = .custom(.init(title: "", description: "Completa todos los campos de Persona \(index + 1)", image: nil))
                    hasErrors = true
                    break
                }
                
                if user.email != user.confirmEmail {
                    self.viewModel.toast = .custom(.init(title: "", description: "El correo y la confirmación no coinciden en Persona \(index + 1)", image: nil))
                    hasErrors = true
                    break
                }
                
                personDataList.append(PersonTicketData(name: user.name, email: user.email, birthDate: user.birthDate, social: user.social))
                
            }
            
            if !hasErrors && personDataList.count == self.viewModel.model.quantity {
                
                let pdfModel = PDFModel(
                    nameEvent: self.viewModel.model.fiesta.name,
                    date: self.viewModel.model.fiesta.fecha,
                    companyuid: self.viewModel.model.companyUid,
                    quantity: self.viewModel.model.quantity,
                    personDataList: personDataList,
                    price: self.viewModel.model.entrada.price,
                    type: self.viewModel.model.entrada.type
                )
                
                print("🔄 Iniciando restauración de capacidad en Firebase")
                print("🔄 \(self.viewModel.model.fiesta.fecha)/////////////\(self.viewModel.model.fiesta.name)////////////\(self.viewModel.model.entrada.type)")
                
                do {
                    try await eventRef.runTransactionBlock { currentData -> TransactionResult in
                        
                        let eventData = currentData.value as? [String: Any] ?? [:]
                        
                        var reservation = eventData["Reservations"] as? [String: Any]
                        reservation?[userUID] = nil // Eliminar solo la reserva
                        currentData.value = eventData
                        print("✅ Transacción completada correctamente: Nodo de usuario eliminado en Reservations")
                        
                        return .success(withValue: currentData)
                    }
                } catch {
                    print("❌ Error en la transacción: \(error.localizedDescription)")
                    
                }
                self.actions.openPDFPay(pdfModel)
            }
            
            else {
                print("Error: No se han completado correctamente todos los datos")
            }
            
            
        } catch let error {
            print("Error durante la transacción: \(error.localizedDescription)")
            self.viewModel.toast = .custom(.init(title: "", description: "Error al confirmar la compra.", image: nil))
        }
    }
    
    private func formatFecha(eventDate: String, startTime: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd-MM-yyyy"
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EEEE, d MMM"
        
        if let date = inputFormatter.date(from: eventDate) {
            return outputFormatter.string(from: date)
        } else {
            return eventDate
        }
    }
    
    private func totalPrice() -> Double {
        let managementFee = 1.0 * Double(viewModel.model.quantity)
        return viewModel.model.price + managementFee
    }
}

struct UserViewTicketModel: Equatable {
    var name: String
    var email: String
    var confirmEmail: String
    var birthDate: String
    var social: String
    
    init(name: String, email: String, confirmEmail: String, birthDate: String, social: String) {
        self.name = name
        self.email = email
        self.confirmEmail = confirmEmail
        self.birthDate = birthDate
        self.social = social
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
    }
    
    static func == (lhs: UserViewTicketModel, rhs: UserViewTicketModel) -> Bool {
        return lhs.email == rhs.email
    }
    
    static func empty() -> UserViewTicketModel {
        return UserViewTicketModel(name: "", email: "", confirmEmail: "", birthDate: "", social: "")
    }
}

struct PersonTicketData: Hashable {
    let name: String
    let email: String
    let birthDate: String
    let social: String
    let id = UUID()
    
    init(name: String, email: String, birthDate: String, social: String) {
        self.name = name
        self.email = email
        self.birthDate = birthDate
        self.social = social
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PersonTicketData, rhs: PersonTicketData) -> Bool {
        return lhs.id == rhs.id
    }
}
