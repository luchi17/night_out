import SwiftUI
import CryptoKit

struct CreatePaymentMethodView: View {
    @State private var cardholderName: String = ""
    @State private var cardNumber: String = ""
    @State private var cardExpiry: String = ""
    @State private var cardCVV: String = ""
    @State private var isCVVVisible: Bool = false
    
    private let secretKey = "1234567890123456" // Clave AES de 16 caracteres
    
    @State private var toast: ToastType?
    
    let onClose: VoidClosure
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo en el Encabezado
            Image("logo_inicio_app")
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.bottom, 24)
                .foregroundStyle(.yellow)
                .padding(.top, 30)
            
            // Campo de Nombre del Titular con Icono
            HStack {
                Image("profile_pic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                
                TextField("",text: $cardholderName, prompt: Text("Nombre del Titular").foregroundColor(.white))
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
            }
            
            // Campo de Número de Tarjeta con Icono
            HStack {
                Image("bank_card")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                TextField("",text: $cardNumber, prompt: Text("Número de Tarjeta").foregroundColor(.white))
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
            }
            
            // Fecha de Vencimiento y CVV
            HStack(spacing: 16) {
                HStack {
                    Image("calendar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                    
                    TextField("",text: $cardExpiry, prompt: Text("MM/AA").foregroundColor(.white))
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.numberPad)
                        .foregroundColor(.white)
                        .onChange(of: cardExpiry) {
                            formatExpiry()
                        }
                }
                
                Spacer()
                
                if isCVVVisible {
                    TextField("",text: $cardCVV, prompt: Text("CVV").foregroundColor(.white))
                        .keyboardType(.numberPad)
                        .foregroundColor(.white)
                } else {
                    SecureField("",text: $cardCVV, prompt: Text("CVV").foregroundColor(.white))
                        .keyboardType(.numberPad)
                        .foregroundColor(.white)
                }
                Spacer()
                
                Button(action: {
                    isCVVVisible.toggle()
                }) {
                    Image(isCVVVisible ? "privacy_eye" : "private_profile")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
            }
            
            // Botón Guardar
            Button(action: {
                savePaymentMethod()
            }) {
                Text("Guardar Datos".uppercased())
                    .font(.system(size: 17))
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 25).fill(Color.grayColor))
            }
            
            Spacer()
        }
        .padding(20)
        .overlay(alignment: .topTrailing, content: {
            HStack {
                Spacer()
                
                Button(action: {
                    print("onclose")
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.top, 30)
            .padding(.trailing, 25)
        })
        .background(Color.blackColor.edgesIgnoringSafeArea(.all))
        .showToast(
            error: (
                type: toast,
                showCloseButton: false,
                onDismiss: {
                    toast = nil
                }
            ),
            isIdle: false
        )
    }
    
    private func formatExpiry() {
        if cardExpiry.count == 2, !cardExpiry.contains("/") {
            cardExpiry.append("/")
        }
    }
    
    private func savePaymentMethod() {
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userId).child("PaymentMethods").getData { error, snapshot in
            guard error == nil else { return }
            if let snapshot = snapshot, snapshot.childrenCount >= 3 {
                self.toast = .custom(.init(title: "", description: "Ya tiene 3 métodos de pago guardados.", image: nil))
                return
            }
            
            if cardholderName.isEmpty || cardNumber.isEmpty || cardExpiry.isEmpty || cardCVV.isEmpty {
                self.toast = .custom(.init(title: "", description: "Por favor, complete todos los campos.", image: nil))
                return
            }
            
            let encryptedCardNumber = encryptCardNumber(cardNumber)
            let paymentMethod: [String: Any] = [
                "cardHolderName": cardholderName,
                "cardNumber": encryptedCardNumber,
                "cardExpiry": cardExpiry,
                "cardCvv": cardCVV,
                "isDefault": snapshot?.childrenCount == 0 //First paymentMethod
            ]
            
            FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userId).child("PaymentMethods").childByAutoId().setValue(paymentMethod) { error, _ in
                if error == nil {
                    self.toast = .success(.init(title: "", description: "Método de pago guardado exitosamente.", image: nil))
                    clearFields()
                } else {
                    self.toast = .custom(.init(title: "", description: "Error al guardar el método de pago.", image: nil))
                }
            }
        }
    }
    
    private func encryptCardNumber(_ cardNumber: String) -> String {
        guard let keyData = secretKey.data(using: .utf8), let cardData = cardNumber.data(using: .utf8) else { return "" }
        let key = SymmetricKey(data: keyData)
        let sealedBox = try? AES.GCM.seal(cardData, using: key)
        return sealedBox?.combined?.base64EncodedString() ?? ""
    }
    
    private func clearFields() {
        cardholderName = ""
        cardNumber = ""
        cardExpiry = ""
        cardCVV = ""
    }
}
