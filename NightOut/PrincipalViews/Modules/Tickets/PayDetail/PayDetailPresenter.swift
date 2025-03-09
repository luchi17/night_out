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
    
    @State var countDownTimer: Timer?
    
    @Published var countdownText: String = ""
    
    @Published var users: [UserViewTicketModel] = []
    
    func saveUserData(at index: Int, name: String, email: String, confirmEmail: String, birthDate: String) {
        users[index] = UserViewTicketModel(name: name, email: email, confirmEmail: confirmEmail, birthDate: birthDate)
    }
    
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
        let pagar: AnyPublisher<Void, Never>
    }
    
    struct UseCases {
        
    }
    
    struct Actions {
        let goBack: VoidClosure
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    private let totalTime: TimeInterval = 5 * 60 // 5 minutos en segundos
    private let reservationRef: DatabaseReference
    private let eventRef: DatabaseReference
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases, model: PayDetailModel) {
        
        self.viewModel = PayDetailViewModel(model: model)
        self.actions = actions
        self.useCases = useCases
        
        self.reservationRef =
        FirebaseServiceImpl.shared
            .getCompanies()
            .child(viewModel.model.companyUid)
            .child("Entradas")
            .child(viewModel.model.fiesta.fecha)
            .child(viewModel.model.fiesta.name)
            .child("types")
            .child(viewModel.model.entrada.type)
            .child("Reservations")
            .child(FirebaseServiceImpl.shared.getCurrentUserUid()!)
        
        self.eventRef = FirebaseServiceImpl.shared
            .getCompanies()
            .child(viewModel.model.companyUid)
            .child("Entradas")
            .child(viewModel.model.fiesta.fecha)
            .child(viewModel.model.fiesta.name)
            .child("types")
            .child(viewModel.model.entrada.type)
    }
    
    func transform(input: Input) {
      
        input
            .viewIsLoaded
            .withUnretained(self)
            .sink { presenter, _ in
                
                presenter.startLocalCountdown()
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
                Task {
                    await presenter.confirmPurchase()
                }
            }
            .store(in: &cancellables)
        
    }
    
    private func startLocalCountdown() {
        viewModel.countDownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            let minutes = Int(self.totalTime / 60)
            let seconds = Int(self.totalTime.truncatingRemainder(dividingBy: 60))
            
            self.viewModel.countdownText = "Tiempo restante: \(String(format: "%02d:%02d", minutes, seconds))"
            
            if self.totalTime <= 0 {
                self.viewModel.countDownTimer?.invalidate()
                Task {
                    await self.restoreCapacity()
                }
            }
        }
    }
    
    private func restoreCapacity() async {
        
        print("🔄 Iniciando restauración de capacidad en Firebase")
        print("🔄 \(viewModel.model.fiesta.fecha)/////////////\(viewModel.model.fiesta.name)////////////\(viewModel.model.entrada.type)")
        
        guard let userUID = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        do {
            
            try await eventRef.runTransactionBlock { (currentData) -> TransactionResult in
                
                guard var eventData = currentData.value as? [String: Any] else {
                    return .abort()
                }
                
                guard var currentCapacityStr = eventData["capacity"] as? String,
                      var currentCapacity = Int(currentCapacityStr) else {
                    print("No se puedo obtener la capacidad")
                    return .abort()
                }
                
                let reservedTickets = self.viewModel.model.quantity
                
                if reservedTickets > 0 {
                    let newCapacity = currentCapacity + reservedTickets
                    eventData["capacity"] = "\(newCapacity)" // Guardar como String
                    
                    var reservations = eventData["Reservations"] as? [String: Any]
                    reservations?[userUID] = nil // Elimina correctamente
                    
                    currentData.value = eventData
                    
                    print("✅ Capacidad = \(currentCapacity)")
                    print("✅ Capacidad restaurada: Nueva capacidad = \(currentCapacityStr) \(newCapacity)")
                } else {
                    print("❌ No hay entradas reservadas para restaurar")
                }
                
                return .success(withValue: currentData)
                print("Capacidad restaurada")
                self.navigateToHomeFragment()
            }
        } catch {
            print("❌ Error en la transacción: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func confirmPurchase() async {
        
        viewModel.countDownTimer?.invalidate() // Detiene el temporizador
        
        guard let userUID = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        // Accede al parent de reservationRef
        do {
            // Ejecutamos la transacción usando async/await
            try await reservationRef.parent?.runTransactionBlock { (currentData) -> TransactionResult in
                guard var eventData = currentData.value as? [String: Any] else {
                    return .abort()
                }
                
                guard let currentCapacity = eventData["capacity"] as? Int else {
                    return .abort()
                }
                
                let reservations = eventData["Reservations"] as? [String: Any]
                var userReservation = reservations?[userUID] as?  [String: Any]
                let reserved = userReservation?["reserved"] as? Int ?? 0
                
                
                if reserved > 0 && currentCapacity >= reserved {
                    eventData["capacity"] = currentCapacity // La reducción ya se hizo al reservar
                    userReservation = nil // Eliminar reserva
                    
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
                    showToast("Completa todos los campos de Persona \(index + 1)")
                    hasErrors = true
                    break
                }
                
                if user.email != user.confirmEmail {
                    showToast("El correo y la confirmación no coinciden en Persona \(index + 1)")
                    hasErrors = true
                    break
                }
                
                personDataList.append(PersonTicketData(name: user.name, email: user.email, birthDate: user.birthDate))
                
            }
            
            //            if !hasErrors && personDataList.count == self.viewModel.model.quantity {
            //                let intent = ActivityPDFEntry()
            //                intent.nameEvent = self.viewModel.model.fiesta.name
            //                intent.date = self.viewModel.model.fiesta.fecha
            //                intent.companyUID = self.viewModel.model.companyUid
            //                intent.ticketQuantity = self.viewModel.model.quantity
            //                intent.personDataList = personDataList
            //
            // Ejecutamos la transacción en el evento
            //                try await eventRef.runTransactionBlock { currentData -> TransactionResult in
            //                    var eventData = currentData.value as? [String: Any] ?? [:]
            //                    eventData["Reservations"]?[userUID] = nil // Eliminar solo la reserva
            //                    currentData.value = eventData
            //                    print("✅ Transacción completada correctamente")
            //                    return .success(withValue: currentData)
            //                }
            
            //                self.present(intent, animated: true, completion: nil)
            //            } else {
            //                print("Error: No se han completado correctamente todos los datos")
            //            }
            
            
            
//            if (!hasErrors && personDataList.size == ticketQuantity) {
//                                    val intent = Intent(this@CompraEntradaActivity, ActivityPDFEntry::class.java).apply {
//                                        putExtra("nameEvent", eventName)
//                                        putExtra("fecha", eventDate)
//                                        putExtra("companyUid", companyUid)
//                                        putExtra("ticket_quantity", ticketQuantity)
//                                        putParcelableArrayListExtra("personDataList", ArrayList(personDataList))
//                                    }
//
//
//
//                                    val eventRef = FirebaseDatabase.getInstance().getReference("Company_Users")
//                                        .child(companyUid!!)
//                                        .child("Entradas")
//                                        .child(eventDate!!)
//                                        .child(eventName!!)
//                                        .child("types")
//                                        .child(ticketType!!)
//
//                                    Log.d("CompraEntradaActivity", "🔄 Iniciando restauración de capacidad en Firebase")
//                                    Log.d("CompraEntradaActivity", "🔄 $eventDate/////////////$eventName////////////$ticketType")
//
//                                    eventRef.runTransaction(object : Transaction.Handler {
//                                        override fun doTransaction(mutableData: MutableData): Transaction.Result {
//                                            // ✅ Elimina únicamente la reserva del usuario sin modificar la capacidad
//                                            mutableData.child("Reservations").child(userUID!!).setValue(null)
//                                            Log.d("CompraEntradaActivity", "✅ Reserva eliminada para el usuario: $userUID")
//
//                                            return Transaction.success(mutableData)
//                                        }
//
//                                        override fun onComplete(databaseError: DatabaseError?, committed: Boolean, dataSnapshot: DataSnapshot?) {
//                                            if (committed) {
//                                                Log.d("CompraEntradaActivity", "✅ Transacción completada correctamente: Nodo de usuario eliminado en Reservations")
//                                            } else {
//                                                Log.e("CompraEntradaActivity", "❌ Error en la transacción: ${databaseError?.message}")
//                                            }
//                                        }
//                                    })
//
//                                    startActivity(intent)
//                                } else {
//                                    Log.e("CompraEntradaActivity", "Error: No se han completado correctamente todos los datos")
//                                }
        } catch let error {
            print("Error durante la transacción: \(error.localizedDescription)")
            showToast("Error al confirmar la compra.")
        }
    }
    
    
    func showToast(_ message: String) {
    }
    
    
    private func navigateToPDFEntry() {
        // Navigation to PDF Entry screen
    }
    
    private func navigateToHomeFragment() {
        // Navigate to home screen
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
    
    init(name: String, email: String, confirmEmail: String, birthDate: String) {
        self.name = name
        self.email = email
        self.confirmEmail = confirmEmail
        self.birthDate = birthDate
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
    }
    
    static func == (lhs: UserViewTicketModel, rhs: UserViewTicketModel) -> Bool {
        return lhs.email == rhs.email
    }
    
    static func empty() -> UserViewTicketModel {
        return UserViewTicketModel(name: "", email: "", confirmEmail: "", birthDate: "")
    }
}

struct PersonTicketData {
    let name: String
    let email: String
    let birthDate: String
    
    init(name: String, email: String, birthDate: String) {
        self.name = name
        self.email = email
        self.birthDate = birthDate
    }
}
