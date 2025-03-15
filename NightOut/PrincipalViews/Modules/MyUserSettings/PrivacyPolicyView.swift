import SwiftUI

struct PrivacyPolicyView: View {
    
    @State private var fadeIn = false
    @State private var slideUp = false
    
    let policyText = """
    Política de Privacidad de NightOut
    
    Esta política de privacidad describe cómo recopilamos, usamos y compartimos su información personal en nuestra aplicación de fiestas. Al utilizar la aplicación, usted acepta la recopilación y el uso de su información conforme a esta política.
    
    1. Recopilación de información:
    Recopilamos la siguiente información:
    - Información de registro: como su nombre, correo electrónico y número de teléfono al crear una cuenta.
    - Información de ubicación: para sugerir eventos cercanos y mejorar la experiencia.
    - Información de uso: datos sobre cómo utiliza nuestra app, incluyendo eventos que le interesan.
    
    2. Uso de la información:
    La información recopilada se utiliza para:
    - Mejorar la experiencia de usuario.
    - Personalizar el contenido y las recomendaciones de eventos.
    - Facilitar la gestión de su cuenta y servicio al cliente.
    
    3. Compartir su información:
    No compartimos su información personal con terceros sin su consentimiento, excepto en las siguientes circunstancias:
    - Proveedores de servicios: proveedores que nos ayudan a operar nuestra aplicación y mejorar el servicio.
    - Obligaciones legales: cuando sea necesario cumplir con obligaciones legales o proteger nuestros derechos.
    
    4. Seguridad:
    Implementamos medidas de seguridad para proteger su información personal y evitar accesos no autorizados.
    
    5. Retención de datos:
    Retenemos su información personal mientras mantenga una cuenta activa o según sea necesario para cumplir con nuestras obligaciones legales.
    
    6. Derechos del usuario:
    Usted tiene derecho a acceder, corregir o eliminar su información personal. Para ejercer estos derechos, contáctenos a través de la aplicación o por correo electrónico.
    
    7. Cambios a esta política:
    Podemos actualizar esta política periódicamente. Notificaremos a los usuarios de cualquier cambio relevante a través de la aplicación.
    
    8. Contacto:
    Si tiene preguntas sobre nuestra política de privacidad, puede contactarnos en soporte@appdefiesta.com.
    
    Última actualización: [Fecha de actualización]
    """
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Política de Privacidad de NightOut")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                Text(policyText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 32)
        }
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
        .background(Color.darkBlueColor.ignoresSafeArea())
    }
}
