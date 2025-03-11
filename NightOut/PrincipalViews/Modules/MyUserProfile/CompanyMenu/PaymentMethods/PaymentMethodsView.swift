import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import CryptoKit

struct CompanyPaymentMethodsView: View {
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
    
    @State private var toast: ToastType?
    @State private var loading: Bool = false
    
    let onClose: VoidClosure
    
    init(onClose: @escaping VoidClosure) {
        self.onClose = onClose
    }
    
    private let secretKey = SymmetricKey(data: "1234567890123456".data(using: .utf8)!)
    
    enum Field: Int, Hashable {
        case nombre, pais, dir, ciudad, cp, iban, swift, fechaNac, nif
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        
        ZStack {
            Color.white

            ScrollView {
                
                VStack(alignment: .leading, spacing: 12) {
                    
                    HStack {
                        Spacer()
                        
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.blackColor)
                        }
                    }
                    .padding(.trailing, 5)
                    .padding(.top, 22)
                    
                    Image("logo_amarillo")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.yellow)
                        .frame(width: 150, height: 150)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 15)

                    Text("INFORMACIÓN:")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                    
                    Text("Tus datos bancarios son encriptados y almacenados de manera segura.\n\nNi siquiera la aplicación NightOut tiene acceso a esta información.\n\nEsta información solo será desencriptada para realizar el pago con una pasarela segura.")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blackColor)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                    
                    Text("Nombre completo del titular de la cuenta")
                        .titleStyle()
                    
                    TextField("", text: $accountHolderName, prompt: Text("Ej. Juan Pérez").foregroundColor(Color.grayColor))
                        .textfieldStyle()
                        .focused($focusedField, equals: .nombre)
                        .onSubmit {
                            self.focusNextField($focusedField)
                        }
                    
                    Text("País")
                        .titleStyle()
                    
                    TextField("", text: $country, prompt: Text("Ej. España").foregroundColor(Color.grayColor))
                        .textfieldStyle()
                        .focused($focusedField, equals: .pais)
                        .onSubmit {
                            self.focusNextField($focusedField)
                        }
                    
                    Text("Dirección")
                        .titleStyle()
                    
                    TextField("", text: $addressLine, prompt: Text("Calle y número").foregroundColor(Color.grayColor))
                        .textfieldStyle()
                        .focused($focusedField, equals: .dir)
                        .onSubmit {
                            self.focusNextField($focusedField)
                        }
                    
                    Text("Ciudad")
                        .titleStyle()
                    
                    TextField("", text: $city, prompt: Text("Ej. Madrid").foregroundColor(Color.grayColor))
                        .textfieldStyle()
                        .focused($focusedField, equals: .ciudad)
                        .onSubmit {
                            self.focusNextField($focusedField)
                        }
                    
                    Text("Código Postal")
                        .titleStyle()
                    
                    TextField("", text: $postalCode, prompt: Text("Ej. 28001").foregroundColor(Color.grayColor))
                        .textfieldStyle()
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .cp)
                        .onSubmit {
                            self.focusNextField($focusedField)
                        }
                    
                    Text("IBAN (En mayúsculas)")
                        .titleStyle()
                    
                    TextField("", text: $iban, prompt: Text("Ej. ES91 2100 0418 4502 0005 1332").foregroundColor(Color.grayColor))
                        .textfieldStyle()
                        .focused($focusedField, equals: .iban)
                        .onSubmit {
                            self.focusNextField($focusedField)
                        }
                        .onChange(of: iban) { old, newValue in
                            iban = formatIban(newValue)
                        }
                    
                    Text("SWIFT/BIC")
                        .titleStyle()
                    
                    TextField("", text: $swift, prompt: Text("Ej. BBVAESMMXXX").foregroundColor(Color.grayColor))
                        .textfieldStyle()
                        .focused($focusedField, equals: .swift)
                        .onSubmit {
                            self.focusNextField($focusedField)
                        }
                        .onChange(of: swift) { old, newValue in
                            swift = newValue.uppercased()
                        }
                    
                    Text("Tipo de cuenta")
                        .titleStyle()
                    
                    HStack {
                        PersonalCheckbox(accountType: "Personal", accountTypeSelected: $accountType)
                        PersonalCheckbox(accountType: "Comercial", accountTypeSelected: $accountType)
                        Spacer()
                    }
                    
                    Text("Fecha de nacimiento (opcional)")
                        .titleStyle()
                        .onChange(of: dob) { old, newValue in
                            dob = formatDate(newValue)
                        }
                    
                    TextField("", text: $dob, prompt: Text("Ej. 01/01/1990").foregroundColor(Color.grayColor))
                        .textfieldStyle()
                        .focused($focusedField, equals: .fechaNac)
                        .onSubmit {
                            self.focusNextField($focusedField)
                        }
                    
                    Text("Número de Identificación Fiscal (opcional)")
                        .titleStyle()
                    
                    TextField("", text: $taxId, prompt: Text("Ej. NIF/CIF").foregroundColor(Color.grayColor))
                        .textfieldStyle()
                        .focused($focusedField, equals: .nif)
                        .onSubmit {
                            self.focusNextField($focusedField)
                        }
                    
                    Button(action: {
                        handleSubmit()
                    }) {
                        Text("Enviar".uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .background(Color.grayColor)
                            .cornerRadius(25)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
//            .padding(.horizontal, 20)
            .clipShape(Rectangle())
            .scrollClipDisabled(false)
            .scrollIndicators(.hidden)
        }
        .edgesIgnoringSafeArea(.bottom)
        .onTapGesture(perform: {
            hideKeyboard()
        })
        .showToast(
            error: (
                type: toast,
                showCloseButton: false,
                onDismiss: {
                    toast = nil
                }
            ),
            isIdle: loading
        )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func validateInputs() -> Bool {
        guard !accountHolderName.isEmpty, !country.isEmpty, !addressLine.isEmpty, !city.isEmpty, !postalCode.isEmpty else {
            self.toast = .custom(.init(title: "Error", description: "Por favor, completa todos los campos obligatorios", image: nil))
            return false
        }
        
        let ibanRegex = "^ES\\d{2}\\d{20}$"
        if !iban.replacingOccurrences(of: " ", with: "").matches(ibanRegex) {
            self.toast = .custom(.init(title: "Error", description: "IBAN debe comenzar con ES seguido de 2 dígitos y luego 20 números", image: nil))
            return false
        }
        
        let dobRegex = "^\\d{2}/\\d{2}/\\d{4}$"
        if !dob.isEmpty && !dob.matches(dobRegex) {
            self.toast = .custom(.init(title: "Error", description: "Fecha de nacimiento debe estar en el formato DD/MM/YYYY", image: nil))
            return false
        }
        
        return true
    }
    
    private func handleSubmit() {
        guard validateInputs() else { return }
        loading = true
        
        let formData: [String: String] = [
            "Nombre": accountHolderName,
            "País": country,
            "Dirección": addressLine,
            "Ciudad": city,
            "Código Postal": postalCode,
            "IBAN": iban.replacingOccurrences(of: " ", with: ""),
            "SWIFT": swift,
            "Tipo de Cuenta": accountType,
            "Fecha de Nacimiento": dob,
            "NIF": taxId
        ]
        
        saveDataToFirebase(data: formData)
    }
    
    private func saveDataToFirebase(data: [String: String]) {
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            self.toast = .custom(.init(title: "Error", description: "Usuario no autenticado.", image: nil))
            loading = false
            return
        }
        
        let encryptedData = encryptData(data)
        FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: userId).child("Metodos_de_Pago").setValue(encryptedData) { error, _ in
            loading = false
            if let error = error {
                self.toast = .custom(.init(title: "Error", description: "Error al guardar los datos: \(error.localizedDescription).", image: nil))
            } else {
                self.toast = .success(.init(title: "Éxito", description: "Datos guardados correctamente.", image: nil))
            }
        }
    }
    
    private func encryptData(_ data: [String: String]) -> [String: String] {
        var encryptedData = [String: String]()
        for (key, value) in data {
            if let encryptedValue = encryptAES(value) {
                encryptedData[key] = encryptedValue
            }
        }
        return encryptedData
    }
    
    private func encryptAES(_ text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try? AES.GCM.seal(data, using: key)
        return sealedBox?.combined?.base64EncodedString()
    }
    
    private func formatIban(_ iban: String) -> String {
        // Eliminar caracteres no alfanuméricos (como espacios y guiones)
        let cleanedIban = iban.uppercased().filter { $0.isLetter || $0.isNumber }
        
        // El IBAN debe tener una longitud de 22 caracteres
        let ibanLength = 22
        
        // Limitar la longitud del IBAN al máximo permitido
        let limitedIban = String(cleanedIban.prefix(ibanLength))
        
        // Insertar espacios cada 4 caracteres
        var formattedIban = ""
        for (index, char) in cleanedIban.enumerated() {
            if index > 1 && (index - 2) % 4 == 0 { // Después de las 2 primeras letras y cada 4 dígitos
                formattedIban.append(" ")
            }
            formattedIban.append(char)
        }
        
        return formattedIban
    }

    private func formatDate(_ date: String) -> String {
        let cleanedDate = date.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        var formattedDate = ""
        for (index, char) in cleanedDate.enumerated() {
            if index == 2 || index == 4 { formattedDate.append("/") }
            formattedDate.append(char)
        }
        return formattedDate
    }
}

private extension View {
    
    @ViewBuilder
    func textfieldStyle() -> some View {
        self
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(Color.blackColor)
            .accentColor(Color.blackColor)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.1))
            )
    }
    
    @ViewBuilder
    func titleStyle() -> some View {
        self
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color.blackColor)
            .padding(.all, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).stroke(Color.blackColor, lineWidth: 1))
    }
}

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}


struct PersonalCheckbox: View {
    let accountType: String
    @Binding var accountTypeSelected: String
    
    var body: some View {
        Button(action: {
            accountTypeSelected = accountType
        }) {
            HStack {
                ZStack {
                    Circle()
                        .stroke(Color.blackColor, lineWidth: 2) // Círculo exterior
                        .frame(width: 20, height: 20)
                    
                    if accountTypeSelected == accountType {
                        Circle()
                            .fill(Color.blackColor)
                            .frame(width: 16, height: 16) // Círculo interno más pequeño para dejar padding
                    }
                }
                
                Text(accountType)
                    .foregroundColor(Color.blackColor)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .buttonStyle(PlainButtonStyle()) // Evita la animación del botón
    }
}
