import SwiftUI

struct ForgotPasswordView: View {
    
    @State var email: String = ""
    
    var sendEmailPassword: InputClosure<String>
    
    var body: some View {
        
        VStack {
            
            Text("Recuperar Contraseña".uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)
            
            Text("Introduce tu correo asociado para continuar.")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 40)
            
            TextField("", text: $email, prompt: Text("Correo asociado a su cuenta...").foregroundColor(.yellow))
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color.clear)
                .foregroundColor(.yellow)
                .accentColor(.yellow)
                .cornerRadius(10)
                .padding(.top, 20)
            
            Button(action: {
                sendEmailPassword(email)
            }) {
                Text("Enviar".uppercased())
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.yellow)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(25)
                    .shadow(radius: 4)
            }
            .padding(.top, 12)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black
        )
    }
}
