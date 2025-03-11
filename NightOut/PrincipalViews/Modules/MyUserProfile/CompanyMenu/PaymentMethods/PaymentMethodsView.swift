import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import CryptoKit

struct PaymentMethodsView: View {
    @State private var accountHolderName: String = ""
    @State private var country: String = ""
    @State private var addressLine: String = ""
    @State private var city: String = ""
    @State private var postalCode: String = ""
    @State private var iban: String = ""
    @State private var swift: String = ""
    @State private var accountType: String = "Personal"
    @State private var dob: String = ""
    @State private var taxId: String = ""
    
    private let secretKey = SymmetricKey(data: "1234567890123456".data(using: .utf8)!)
    private var auth = Auth.auth()
    private var database = Database.database().reference()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image("logo_inicio_app")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .scaledToFit()
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)

                Text("INFORMACION:")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.bottom, 8)

                Text("Tus datos bancarios son encriptados y almacenados de manera segura.\n\nNi siquiera la aplicación NightOut tiene acceso a esta información.\n\nEsta información solo será desencriptada para realizar el pago con una pasarela segura.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(8)
                    .padding(.bottom, 20)

                Text("Nombre completo del titular de la cuenta")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                TextField("Ej. Juan Pérez", text: $accountHolderName)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Text("País")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                TextField("Ej. España", text: $country)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Text("Dirección")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                TextField("Calle y número", text: $addressLine)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Text("Ciudad")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                TextField("Ej. Madrid", text: $city)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Text("Código Postal")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                TextField("Ej. 28001", text: $postalCode)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Text("IBAN (En mayúsculas)")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                TextField("Ej. ES91 2100 0418 4502 0005 1332", text: $iban)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Text("SWIFT/BIC")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                TextField("Ej. BBVAESMMXXX", text: $swift)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Text("Tipo de cuenta")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                HStack {
                    Button(action: {
                        accountType = "Personal"
                    }) {
                        Text("Personal")
                            .padding()
                            .background(accountType == "Personal" ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    Button(action: {
                        accountType = "Comercial"
                    }) {
                        Text("Comercial")
                            .padding()
                            .background(accountType == "Comercial" ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }

                Text("Fecha de nacimiento (opcional)")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                TextField("Ej. 01/01/1990", text: $dob)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Text("Número de Identificación Fiscal (opcional)")
                    .font(.system(size: 16, weight: .bold))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)

                TextField("Ej. NIF/CIF", text: $taxId)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Button(action: {
//                    savePaymentMethod()
                }) {
                    Text("Enviar")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .background(Color.white)
    }
    
//    private func toggleCvvVisibility() {
//            isCvvVisible.toggle()
//    }
//        
//        private func addSlashToExpiry(_ text: String) {
//            if text.count == 2 && !text.contains("/") {
//                cardExpiry = "\(text)/"
//            }
//        }
//    
//    private func savePaymentMethod() {
//            guard !cardholderName.isEmpty, !cardNumber.isEmpty, !cardExpiry.isEmpty, !cardCvv.isEmpty else {
//                showToastMessage("Please fill in all fields")
//                return
//            }
//            
//            let userId = auth.currentUser?.uid ?? ""
//            
//            database.child("Users").child(userId).child("PaymentMethods").observeSingleEvent(of: .value) { snapshot in
//                let isFirstMethod = snapshot.childrenCount == 0
//                let encryptedCardNumber = encryptCardNumber(cardNumber)
//                
//                let paymentMethod = [
//                    "cardHolderName": cardholderName,
//                    "cardNumber": encryptedCardNumber,
//                    "cardExpiry": cardExpiry,
//                    "cardCvv": cardCvv,
//                    "isDefault": isFirstMethod
//                ]
//                
//                database.child("Users").child(userId).child("PaymentMethods").childByAutoId().setValue(paymentMethod) { error, _ in
//                    if let error = error {
//                        showToastMessage("Error saving payment method: \(error.localizedDescription)")
//                    } else {
//                        showToastMessage("Payment method saved successfully")
//                        clearFields()
//                    }
//                }
//            }
//        }
//        
//        private func encryptCardNumber(_ cardNumber: String) -> String {
//            guard let data = cardNumber.data(using: .utf8) else { return "" }
//            let key = SymmetricKey(data: secretKey.data(using: .utf8)!)
//            
//            do {
//                let encryptedData = try AES.GCM.seal(data, using: key).combined
//                return encryptedData?.base64EncodedString() ?? ""
//            } catch {
//                return ""
//            }
//        }
//        
//        private func showToastMessage(_ message: String) {
//            toastMessage = message
//            showToast = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                showToast = false
//            }
//        }
//        
//        private func clearFields() {
//            cardholderName = ""
//            cardNumber = ""
//            cardExpiry = ""
//            cardCvv = ""
//        }
//    }
//    
    
}
