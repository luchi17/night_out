import SwiftUI

struct PayUserCardView: View {
    @Binding var user: UserViewTicketModel
    @Binding var showDatePicker: Bool
    
    @Binding var selectedUserIndex: Int?
    var index: Int
    
    @FocusState private var focusedField: Field?
    
    enum Field: Int, Hashable {
        case name, birthDate, email, confirmemail
    }
    
    var overlay: some View {
        Rectangle()
            .frame(height: 2)
            .foregroundColor(.white)
            .padding(.bottom, 0)
    }
    
    var body: some View {
        
        VStack(spacing: 16) {
            Text("Persona \(index + 1)")
                .foregroundStyle(.white)
            
            HStack {
                Image("profile_pic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
                
                TextField("", text: $user.name, prompt: Text("Nombre y Apellido").foregroundColor(.white))
                    .focused($focusedField, equals: .name)
                    .foregroundColor(.white) // Color del texto
                    .accentColor(.white)
                    .overlay(alignment: .bottom, content: {
                        overlay
                    })
                    .focused($focusedField, equals: .name)
                    .onSubmit {
                        self.focusNextField($focusedField)
                    }
            }
            
            HStack {
                Image("calendario")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
                
                TextField("", text: Binding(
                    get: { user.birthDate },
                    set: { _ in } // No hace nada al escribir
                ),
                          prompt: Text("Fecha de Nacimiento").foregroundColor(.white))
                    .foregroundColor(.white) // Color del texto
                    .accentColor(.white)
                    .disabled(true) // Deshabilita la escritura
                    .focused($focusedField, equals: .birthDate)
                    .overlay(alignment: .bottom, content: {
                        overlay
                    })
                    .onSubmit {
                        self.focusNextField($focusedField)
                    }
            }
            .onTapGesture {
               selectedUserIndex = index
               showDatePicker = true
            }
            
            HStack {
                Image("arroba")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
                
                TextField("", text: $user.email, prompt: Text("Correo Electrónico").foregroundColor(.white))
                    .foregroundColor(.white) // Color del texto
                    .accentColor(.white)
                    .focused($focusedField, equals: .email)
                    .overlay(alignment: .bottom, content: {
                        overlay
                    })
                    .onSubmit {
                        self.focusNextField($focusedField)
                    }
                
            }
            
            HStack {
                Image("arroba")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
                
                TextField("", text: $user.confirmEmail, prompt: Text("Confirmar Correo").foregroundColor(.white))
                    .foregroundColor(.white) // Color del texto
                    .accentColor(.white)
                    .focused($focusedField, equals: .confirmemail)
                    .overlay(alignment: .bottom, content: {
                        overlay
                    })
                    .onSubmit {
                        self.focusNextField($focusedField)
                    }
            }
            .padding(.bottom, 10)
        }
        .padding(16)
        .background(Color.grayColor)
        .cornerRadius(20)
    }
}


struct UserBirthDatePickerView: View {
    @Binding var selectedDate: Date?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            DatePicker("Selecciona una fecha", selection: Binding<Date> (
                get: { selectedDate ?? Date() },
                set: { newValue in
                    selectedDate = newValue
                }),
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()

            Button("Escoger fecha".uppercased()) {
                dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button(action: {
                dismiss()
            }) {
                Text("Cerrar")
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }
}

extension View {
    
    func focusNextField<F: RawRepresentable>(_ field: FocusState<F?>.Binding) where F.RawValue == Int {
            guard let currentValue = field.wrappedValue else { return }
            let nextValue = currentValue.rawValue + 1
            if let newValue = F.init(rawValue: nextValue) {
                field.wrappedValue = newValue
            }
        }
    
}
