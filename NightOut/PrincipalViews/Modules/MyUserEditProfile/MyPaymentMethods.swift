import SwiftUI
import Firebase
import FirebaseAuth

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
                .padding(.top, 30)
            
            List {
                ForEach($viewModel.paymentMethods) { method in
                    CardPaymentMethodView(
                        method: method,
                        isCVVVisible: $isCVVVisible
                    )
                    .padding(.all, 5)
                    .background(Color.black)
                    .onLongPressGesture {
                        selectedPaymentMethod = method.wrappedValue
                        showMenu = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            
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
                    .frame(width: 30, height: 30)
                    .foregroundColor(.yellow)
                    .padding()
                    .background(Circle().fill(Color.blackColor))
            }
            .padding(.bottom)
        }
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
        .background(Color.blackColor.ignoresSafeArea())
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
            Button("Borrar", role: .cancel) {
                showMenu.toggle()
                showAlert.toggle()
            }
            Button("Establecer como predeterminado", role: .destructive) {
                if let selectedPaymentMethod = selectedPaymentMethod {
                    viewModel.setDefaultPaymentMethod(paymentId: selectedPaymentMethod.id)
                }
            }
        }
//        .sheet(isPresented: $openAddPaymentMethod) {
////            MyUserCompanySettingsView(presenter: companySettingsPresenter)
////            .presentationDetents([.large])
////            .presentationDragIndicator(.visible)
//            print("$openAddPaymentMethod")
//        }
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
    
    private let db = Database.database().reference()
    
    func fetchPaymentMethods() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let ref = db.child("Users").child(userId).child("PaymentMethods")

        ref.observe(.value) { snapshot in
            
            var methods: [PaymentMethod] = []
            
            for child in snapshot.children {
                
                if let snapshot = child as? DataSnapshot,
                   let value = snapshot.value as? [String: Any],
                   let id = snapshot.key as String?,
                   let cardNumber = value["cardNumber"] as? String,
                   let cardExpiry = value["cardExpiry"] as? String,
                   let cardCvv = value["cardCvv"] as? String,
                   let isDefault = value["isDefault"] as? Bool {
                    
                   let method = PaymentMethod(id: id, cardNumber: cardNumber, cardExpiry: cardExpiry, cardCvv: cardCvv, isDefault: isDefault)
                   methods.append(method)
                }
            }
            self.paymentMethods = methods
        }
    }

    func deletePaymentMethod(paymentId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = db.child("Users").child(userId).child("PaymentMethods").child(paymentId)
        
        ref.removeValue { error, _ in
            if error == nil {
                DispatchQueue.main.async {
                    self.paymentMethods.removeAll { $0.id == paymentId }
                }
            }
        }
    }

    func setDefaultPaymentMethod(paymentId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let ref = db.child("Users").child(userId).child("PaymentMethods")
        
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
}


struct CardPaymentMethodView: View {
    
    @Binding var method: PaymentMethod
    @Binding var isCVVVisible: Bool
    
    var body: some View {
        HStack {
            Image("bank_card")
                .foregroundColor(.white)
                .scaledToFit()
                .frame(width: 40)
            
            VStack {
                Text("**** **** **** \(method.cardNumber.suffix(4))")
                    .foregroundColor(.white)
                    .font(.headline)
                
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
            
            VStack {
                if method.isDefault {
                    Text("✓")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                } else {
                    Spacer()
                }
                
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
        }
    }
}
