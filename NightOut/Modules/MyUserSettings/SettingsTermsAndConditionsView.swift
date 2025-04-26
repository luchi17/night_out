import SwiftUI

struct SettingsTermsAndConditionsView: View {
    @State private var fadeIn = false
    @State private var slideUp = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Términos y Condiciones Legales")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                Text("""
                Estos términos y condiciones están destinados a regular el uso de nuestra aplicación. A continuación, se detallan todos los temas legales relevantes conforme a las leyes de protección de datos, el código civil y penal, y las normativas vigentes. Al utilizar la aplicación, el usuario acepta y está de acuerdo con estos términos en su totalidad.

                1. **Licencia de Uso:**
                La app es una plataforma de entretenimiento y redes sociales. El usuario obtiene una licencia no exclusiva, revocable y limitada para usar la app conforme a estos términos. La licencia no otorga al usuario ningún derecho sobre el código o el contenido de la app.

                2. **Protección de Datos y Privacidad:**
                Nos comprometemos a cumplir con las leyes de protección de datos, como el RGPD en la UE y la LFPD en otras jurisdicciones. Recopilamos y procesamos únicamente la información necesaria para mejorar la experiencia del usuario en la app.

                3. **Tratamiento de Datos Sensibles:**
                Ciertos datos pueden considerarse sensibles, como ubicación y contactos. Se recopilan y procesan solo con el consentimiento explícito del usuario y de acuerdo con las leyes aplicables.

                4. **Eliminación de Fotos y Mensajes:**
                Todos los archivos multimedia, mensajes y publicaciones en la app se eliminan automáticamente cada 24 horas para proteger la privacidad del usuario y evitar la acumulación de datos innecesarios.

                5. **Seguridad de la Información:**
                Implementamos medidas de seguridad avanzadas para proteger la información personal de los usuarios. Sin embargo, el usuario acepta que no podemos garantizar la seguridad absoluta y reconoce los riesgos asociados al uso de plataformas digitales.

                6. **Pagos y Suscripciones:**
                Ciertas funcionalidades de la app pueden requerir pagos o suscripciones. Los pagos no son reembolsables una vez procesados, salvo en circunstancias requeridas por ley.

                7. **Reembolsos y Derecho de Cancelación:**
                El usuario tiene derecho a cancelar la suscripción en cualquier momento. No ofrecemos reembolsos parciales a menos que la legislación aplicable lo exija.

                8. **Responsabilidad por Contenido:**
                Los usuarios son responsables de todo el contenido que publiquen o compartan a través de la app y deben abstenerse de publicar contenido que sea ilegal, ofensivo o difamatorio.

                9. **Prohibiciones y Actividades Ilegales:**
                - Compartir contenido que infrinja derechos de autor.
                - Realizar fraudes o engaños.
                - Acosar o intimidar a otros usuarios.
                - Intentar hackear o acceder sin autorización a los sistemas internos de la app.

                10. **Limitación de Responsabilidad:**
                La app se proporciona tal cual, sin garantías adicionales.

                11. **Publicidad y Marketing:**
                Podemos mostrar anuncios personalizados en conformidad con las normativas de publicidad y leyes de protección al consumidor.

                12. **Modificación de los Términos:**
                Nos reservamos el derecho de modificar estos términos en cualquier momento.

                13. **Eliminación de Cuenta y Datos:**
                El usuario puede solicitar la eliminación de su cuenta y datos personales en cualquier momento.

                14. **Legislación Aplicable y Jurisdicción:**
                Estos términos y condiciones se rigen por la legislación aplicable en el país en el que se desarrolla la app.

                15. **Contacto:**
                Para consultas, puede contactarnos en soporte@appdefiesta.com.

                Última actualización: [Fecha de actualización]
                """)
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
