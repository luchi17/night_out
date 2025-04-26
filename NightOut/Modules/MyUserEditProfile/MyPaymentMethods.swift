import SwiftUI
import Firebase
import FirebaseAuth
import CryptoKit

struct PaymentMethod: Identifiable, Codable {
    let id: String
    let cardNumber: String
    let cardExpiry: String
    let cardCvv: String
    var isDefault: Bool
}

struct MyPaymentMethodsView: View {
    
    @StateObject private var viewModel = MyPaymentMethodsViewModel()
    
    @State private var showAlert = false
    @State private var showMenu = false
    
    @State private var selectedPaymentMethod: PaymentMethod?
    
    @State private var openAddPaymentMethod = false
    
    @State private var toast: ToastType?
    
    @State private var isCVVVisible: Bool = false
    
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            Text("Tus Métodos de Pago")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .padding(.vertical, 30)
            
            ForEach($viewModel.paymentMethods) { method in
                CardPaymentMethodView(
                    method: method,
                    isCVVVisible: $isCVVVisible
                )
                .padding(.all, 8)
                .background(Color.black)
                .cornerRadius(8)
                .frame(height: 75)
                .onLongPressGesture {
                    selectedPaymentMethod = method.wrappedValue
                    showMenu = true
                }
            }
            
            Spacer()
            
            Button(action: {
                if viewModel.paymentMethods.count < 3 {
                    openAddPaymentMethod = true
                } else {
                    self.toast = .custom(.init(title: "", description: "Debes eliminar un método de pago para añadir otro.", image: nil))
                }
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(.yellow)
                    .padding(.all, 7)
                    .overlay(Circle().stroke(Color.yellow, lineWidth: 1.5))
            }
            .padding(.bottom)
        }
        .padding(.horizontal, 20)
        .background(Color.blackColor.ignoresSafeArea())
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
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Eliminar Método"),
                message: Text("¿Seguro que deseas eliminar este método de pago?"),
                primaryButton: .destructive(Text("Eliminar")) {
                    if let method = selectedPaymentMethod {
                        viewModel.deletePaymentMethod(paymentId: method.id)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .confirmationDialog("Menú", isPresented: $showMenu) {
            if let selected = selectedPaymentMethod, !selected.isDefault {
                Button("Establecer como predeterminado", role: .none) {
                    if let selectedPaymentMethod = selectedPaymentMethod {
                        viewModel.setDefaultPaymentMethod(paymentId: selectedPaymentMethod.id)
                    }
                }
            }
           
            Button("Borrar", role: .destructive) {
                showMenu = false
                showAlert.toggle()
            }
            Button("Cancelar", role: .cancel) {}
        }
        .sheet(isPresented: $openAddPaymentMethod) {
            CreatePaymentMethodView(onClose: {
                openAddPaymentMethod = false
                viewModel.fetchPaymentMethods()
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .presentationDetents([.large])
        }
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
        .onAppear {
            viewModel.fetchPaymentMethods()
        }
    }
}

class MyPaymentMethodsViewModel: ObservableObject {
    
    @Published var paymentMethods: [PaymentMethod] = []

    private let secretKey = "1234567890123456" // Clave AES de 16 caracteres

    func fetchPaymentMethods() {
        
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let ref = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userId).child("PaymentMethods")

        ref.observe(.value) { [weak self] snapshot in
            
            guard let self = self else { return }
            var methods: [PaymentMethod] = []
            
            for child in snapshot.children {
                
                if let snapshot = child as? DataSnapshot,
                   let value = snapshot.value as? [String: Any],
                   let id = snapshot.key as String?,
                   let cardNumber = value["cardNumber"] as? String,
                   let cardExpiry = value["cardExpiry"] as? String,
                   let cardCvv = value["cardCvv"] as? String {
                
                   let isDefault = value["isDefault"] as? Bool ?? false
                
                   let decriptedCardNumber = self.decryptCardNumber(encryptedCard: cardNumber) ?? "**** **** **** ****"
                    
                   let method = PaymentMethod(id: id, cardNumber: decriptedCardNumber, cardExpiry: cardExpiry, cardCvv: cardCvv, isDefault: isDefault)
                   methods.append(method)
                }
            }
            self.paymentMethods = methods
        }
    }

    func deletePaymentMethod(paymentId: String) {
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let ref = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userId).child("PaymentMethods").child(paymentId)
        
        ref.removeValue { error, _ in
            if error == nil {
                DispatchQueue.main.async {
                    self.paymentMethods.removeAll { $0.id == paymentId }
                }
            }
        }
    }

    func setDefaultPaymentMethod(paymentId: String) {
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        let ref = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userId).child("PaymentMethods")
        
        // Primero, establecer el nuevo método como predeterminado
        ref.child(paymentId).child("isDefault").setValue(true)
        
        // Luego, marcar los demás como no predeterminados
        for method in paymentMethods where method.id != paymentId {
            ref.child(method.id).child("isDefault").setValue(false)
        }
        
        DispatchQueue.main.async {
            self.paymentMethods = self.paymentMethods.map { method in
                var updatedMethod = method
                updatedMethod.isDefault = (method.id == paymentId)
                return updatedMethod
            }
        }
    }

    func decryptCardNumber(encryptedCard: String) -> String? {
        guard let keyData = secretKey.data(using: .utf8),
              let encryptedData = Data(base64Encoded: encryptedCard),
              let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData),
              let decryptedData = try? AES.GCM.open(sealedBox, using: SymmetricKey(data: keyData))
        else {
            print("Error: No se pudo desencriptar la tarjeta")
            return nil
        }
        
        return String(data: decryptedData, encoding: .utf8)
    }

}


struct CardPaymentMethodView: View {
    
    @Binding var method: PaymentMethod
    @Binding var isCVVVisible: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image("bank_card")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 50)
            
            VStack(spacing: 15) {
                Text("\(method.cardNumber)")
                    .foregroundColor(.white)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Text("\(method.cardExpiry)")
                        .foregroundColor(.white)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(isCVVVisible ? "\(method.cardExpiry)" : "***")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        
                }
            }
            
            Spacer()
            
            VStack {
                
                Spacer()
                
                Image(isCVVVisible ? "privacy_eye" : "private_profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .onTapGesture {
                        isCVVVisible.toggle()
                    }
                
                Spacer()
            }
            .overlay(alignment: .topTrailing) {
                if method.isDefault {
                    Text("✓")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                        .offset(x: 2,y: -5)
                }
            }
        }
    }
}
