import SwiftUI

struct PayUserCardView: View {
    @Binding var user: UserViewTicketModel
    @Binding var showDatePicker: Bool
    
    var index: Int
    
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
                    .foregroundColor(.white) // Color del texto
                    .accentColor(.white)
                    .overlay(alignment: .bottom, content: {
                        overlay
                    })
            }
            
            HStack {
                Image("calendario")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
                
                TextField("", text: $user.birthDate, prompt: Text("Fecha de Nacimiento").foregroundColor(.white))
                    .foregroundColor(.white) // Color del texto
                    .accentColor(.white)
                    .overlay(alignment: .bottom, content: {
                        overlay
                    })
                    .onTapGesture {
                       showDatePicker = true
                    }
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
                    .overlay(alignment: .bottom, content: {
                        overlay
                    })
                
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
                    .overlay(alignment: .bottom, content: {
                        overlay
                    })
            }
        }
        .padding(16)
        .background(Color.grayColor)
        .cornerRadius(20)
    }
}


struct UserBirthDatePickerView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack {
            DatePicker("Selecciona una fecha", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle()) // Estilo gráfico de calendario
                            .padding()
            
            Button("Cerrar") {
                // Close the date picker
              
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
