import SwiftUI

struct PrivacyPolicyView: View {
    @State private var fadeIn = false
    @State private var slideUp = false
    
    var body: some View {
        Text("Aquí va la política de privacidad.") // Cambia esto por tu texto real
            .multilineTextAlignment(.center)
            .padding()
            .opacity(fadeIn ? 1 : 0) // Control de opacidad para el efecto fade-in
            .offset(y: slideUp ? 0 : 100) // Control de desplazamiento para el efecto slide-up
            .animation(.easeInOut(duration: 1), value: fadeIn) // Animación de fade-in
            .animation(.easeInOut(duration: 1), value: slideUp) // Animación de slide-up
            .onAppear {
                // Iniciar ambas animaciones cuando la vista aparece
                fadeIn = true
                slideUp = true
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white) // Fondo blanco para asemejarse al diseño original
    }
}
