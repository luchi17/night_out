import SwiftUI

struct TutorialSettingsView: View {
    
    var close: VoidClosure
    
    var body: some View {
        ZStack {
            Color.darkBlueColor.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                Image("logo_amarillo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.white)
                    
                Text("¡Bienvenido a NightOut!\n👤Una pequeña ayuda para entender la app")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    
                Text("¿Cómo funciona NightOut?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    
                Text("✨ NightOut transforma tus noches en experiencias inolvidables\n- Haz clic en el logo de NightOut en la feed a las 21:00 horas para acceder al exclusivo Social Night Out. 🌟\n- Explora el calendario para:\n  • Buscar entradas para tus discotecas favoritas. 🎟️\n  • Descubrir las mejores opciones para esta noche. 🎶\n- Participa en ligas emocionantes al poner el emoticono de la copa en tu foto y crea tus propias competiciones. 🏅\n- Aprovecha el mapa para:\n  • Encontrar los lugares más increíbles cerca de ti. 📍\n  • Ver quién asistirá a cada evento. 👥")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Button(action: {
                    close()
                }) {
                    Text("Empezar buscando amigos".uppercased())
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.grayColor)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 32)
        }
    }
}
