import Combine
import SwiftUI
import Firebase
import CoreLocation
import CommonCrypto

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
    
    @Published var urlToLoad: URL? = nil
    @Published var isPaymentProcessing: Bool = false
    
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
                    self.startPayment()
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
    
    // Iniciar el proceso de pago
        func startPayment() {
            self.viewModel.isPaymentProcessing = true
            generatePaymentForm()
        }
    
    let claveComercio = "999008881"
    // Crear el formulario HTML y calcular la URL para cargar
        func generatePaymentForm() {
            
            let dsSignatureVersion = "HMAC_SHA256_V1"
            let dsMerchantParameters = createMerchantParameters()
            let dsSignature = try? createMerchantSignature(claveComercio: self.claveComercio)
            
            let html = """
            <html>
            <body>
            <form name="form" action="https://sis-t.redsys.es:25443/sis/realizarPago" method="POST">
                <input type="hidden" name="Ds_SignatureVersion" value="HMAC_SHA256_V1"/>
                <input type="hidden" name="Ds_MerchantParameters" value="\(dsMerchantParameters)"/>
                <input type="hidden" name="Ds_Signature" value="\(dsSignature)"/>
                <input type="submit" value="Pagar ahora"/>
            </form>
            <script>
                document.forms["form"].submit();
            </script>
            </body>
            </html>
            """
            
            // Crear una URL de datos codificada en base64
            if let htmlData = html.data(using: .utf8) {
                let base64HTML = htmlData.base64EncodedString()
                if let url = URL(string: "data:text/html;base64,\(base64HTML)") {
                    self.viewModel.urlToLoad = url
                }
            }
        }
    
    func createMerchantSignature(claveComercio: String) throws -> String {
        // Crea los parámetros del comercio (suponiendo que ya tengas la función createMerchantParameters implementada)
        let merchantParams = createMerchantParameters()

        // Decodificar la clave de comercio desde Base64
        guard let claveData = Data(base64Encoded: claveComercio) else {
            throw NSError(domain: "Invalid Base64 encoding", code: 1, userInfo: nil)
        }

        let secretKc = toHexadecimal(data: claveData)

        // Cifrar la clave con 3DES (suponiendo que tienes implementado encrypt_3DES)
        let secretKo = try encrypt3DES(key: secretKc, order: getOrder())

        // Calcular el HMAC-SHA256
        let hash = try mac256(merchantParams: merchantParams, secretKo: secretKo)

        // Codificar el resultado en Base64
        let base64Hash = hash.base64EncodedString()
        
        return base64Hash
    }

    func createMerchantParameters() -> String {
        // Implementa la creación de los parámetros del comercio según lo que necesites
        let parameters = [
            "DS_MERCHANT_AMOUNT": "145",  // Importe en céntimos (por ejemplo, 10€ = 1000 céntimos)
                "DS_MERCHANT_CURRENCY": "978", // Código de moneda (978 = EUR)
            "DS_MERCHANT_MERCHANTCODE": self.claveComercio,
                "DS_MERCHANT_MERCHANTURL": "http://www.prueba.com/urlNotificacion.php", // URL de notificación
                "DS_MERCHANT_ORDER": "1446068581", // ID único de la orden
                "DS_MERCHANT_TERMINAL": "1",
                "DS_MERCHANT_TRANSACTIONTYPE": "0", // Tu código de comercio
                "DS_MERCHANT_URLKO": "http://www.prueba.com/urlKO.php", // URL de error
                "DS_MERCHANT_URLOK": "http://www.prueba.com/urlOK.php"  // URL de exito
        ]
        
        // Convertir el diccionario a JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) {
            // Codificar en base64
            let Ds_MerchantParameters = jsonData.base64EncodedString()
            
            // Imprimir el resultado
            print("JSON en base64: \(Ds_MerchantParameters)")
            
            return Ds_MerchantParameters
            
        } else {
            print("Error al convertir el diccionario a JSON")
            return ""
        }
    }

    func toHexadecimal(data: Data) -> String {
        return data.map { String(format: "%02hhx", $0) }.joined()
    }

    func getOrder() -> String {
        // Devuelve el número de orden del pedido
        return "123456789"
    }

    // Encrypt 3DES
    func encrypt3DES(key: String, order: String) throws -> Data {
        // Implementa la lógica de 3DES usando CommonCrypto
        let keyData = key.data(using: .utf8)!
        let orderData = order.data(using: .utf8)!

        var cryptData = Data(count: orderData.count + kCCBlockSize3DES)
        var numBytesEncrypted: size_t = 0

        // Crea una copia de cryptData para evitar conflictos de acceso
        var cryptDataCopy = cryptData
        
        let status = cryptDataCopy.withUnsafeMutableBytes { cryptBytes in
            orderData.withUnsafeBytes { dataBytes in
                keyData.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithm3DES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, kCCKeySize3DES,
                        nil,
                        dataBytes.baseAddress, dataBytes.count,
                        cryptBytes.baseAddress, cryptData.count,
                        &numBytesEncrypted
                    )
                }
            }
        }

        if status == kCCSuccess {
            cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
            return cryptData
        } else {
            throw NSError(domain: "3DES encryption failed", code: Int(status), userInfo: nil)
        }
    }

    // Calcular HMAC-SHA256
    func mac256(merchantParams: String, secretKo: Data) throws -> Data {
        let message = merchantParams.data(using: .utf8)!
        var hmac = Data(count: Int(CC_SHA256_DIGEST_LENGTH))

        hmac.withUnsafeMutableBytes { hmacBytes in
            message.withUnsafeBytes { messageBytes in
                secretKo.withUnsafeBytes { keyBytes in
                    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, secretKo.count,
                           messageBytes.baseAddress, message.count, hmacBytes.baseAddress)
                }
            }
        }

        return hmac
    }
    
//    func openPaymentGateway(with parameters: [String: String]) {
//            //PROD: https://sis.redsys.es/sis/realizarPago
//            let paymentUrl = "https://sis-t.redsys.es:25443/sis/realizarPago"
//        
//            var components = URLComponents(string: paymentUrl)!
//            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
//
//            // Creamos una vista de pago (WKWebView)
//            let webView = WKWebView()
//            guard let url = components.url else { return }
//            
//            let request = URLRequest(url: url)
//            webView.load(request)
//            
//            // Presentar la vista del web view (puedes presentarla en tu UI de la app)
//            // Aquí depende de cómo quieras manejar la UI, podrías presentar el web view en una nueva vista.
//            let viewController = UIViewController()
//            viewController.view = webView
//            navigationController?.pushViewController(viewController, animated: true)
//    }

    
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
                
                personDataList.append(PersonTicketData(name: user.name, email: user.email, birthDate: user.birthDate))
                
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

struct PersonTicketData: Hashable {
    let name: String
    let email: String
    let birthDate: String
    let id = UUID()
    
    init(name: String, email: String, birthDate: String) {
        self.name = name
        self.email = email
        self.birthDate = birthDate
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PersonTicketData, rhs: PersonTicketData) -> Bool {
        return lhs.id == rhs.id
    }
}
