import SwiftUI

struct TermsAndConditionsView: View {
    @Binding var isAccepted: Bool
    @State private var showTermsSheet: Bool = false
    
    var body: some View {
        HStack {
            Toggle(isOn: $isAccepted) {
                HStack {
                    Text("He leído y acepto los ")
                        .foregroundColor(.black)
                    Button(action: {
                        // Mostrar la sheet con los términos y condiciones
                        showTermsSheet.toggle()
                    }) {
                        Text("Términos y Condiciones")
                            .foregroundColor(.blue) // Color azul para el texto
                    }
                }
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding()
        .sheet(isPresented: $showTermsSheet) {
            // Vista que se muestra en la sheet
            TermsAndConditionsSheetView(onCloseTap: {
                showTermsSheet.toggle()
            })
        }
    }
}

struct TermsAndConditionsSheetView: View {
    
    var onCloseTap: VoidClosure
    
    var body: some View {
        VStack {
            Text("Términos y Condiciones")
                .font(.title)
                .padding()
            
            ScrollView {
                Text("""
                   1. **Tratamiento de Datos Personales:**
                           - Todas las fotos subidas se almacenarán durante 24 horas y luego serán eliminadas automáticamente del servidor.
                           - Todos los datos proporcionados durante el registro, así como la foto de perfil, se guardarán de manera segura y no se harán públicos, a menos que se requiera por ley.

                        2. **Conducta del Usuario:**
                           - No se permite el uso del servicio para compartir contenido ofensivo, abusivo, difamatorio, o que incite al odio. Cualquier conducta inapropiada, incluidos insultos, acoso o amenazas hacia otros usuarios, resultará en la suspensión o terminación de la cuenta.
                           - Está prohibido subir contenido que infrinja los derechos de otros, incluidos derechos de autor, marcas registradas, privacidad o derechos de publicidad.

                        3. **Contenido Prohibido:**
                           - Queda estrictamente prohibido subir contenido sexual explícito, pornográfico, o cualquier material que sea considerado inapropiado o ilegal.
                           - No se permite la publicación de imágenes que incluyan menores de edad de manera que infrinja la ley o que pueda considerarse explotación infantil.
                           - Cualquier contenido que promueva la violencia, el terrorismo, o actividades ilegales será eliminado de inmediato y se tomarán las acciones legales correspondientes.

                        4. **Protección de Menores:**
                           - El uso del servicio está limitado a personas mayores de edad. Los menores de 18 años no están autorizados a utilizar el servicio. Se tomarán medidas para proteger la privacidad y seguridad de los menores, y se procederá con la eliminación de cualquier cuenta o contenido relacionado con menores que se detecte.

                        5. **Derechos de Autor y Propiedad Intelectual:**
                           - Los usuarios conservan los derechos de autor sobre el contenido que suben, pero otorgan a la plataforma una licencia no exclusiva, transferible, sublicenciable, y libre de regalías para usar, reproducir, modificar, y distribuir dicho contenido en el marco de los servicios ofrecidos.

                        6. **Modificaciones y Actualizaciones:**
                           - Nos reservamos el derecho a modificar estos términos y condiciones en cualquier momento. Las modificaciones serán efectivas a partir de su publicación en el sitio web o aplicación. Se recomienda a los usuarios revisar periódicamente los términos y condiciones para estar al tanto de cualquier cambio.

                        7. **Contacto:**
                           - Para cualquier pregunta o inquietud relacionada con estos términos y condiciones, los usuarios pueden ponerse en contacto con el soporte al cliente a través de [correo electrónico] o [formulario de contacto en el sitio web].
                """)
                .padding()
            }
            
            Button("Cerrar") {
                onCloseTap()
                // Acción para cerrar la sheet
                // La sheet se cerrará automáticamente al pulsar el botón
            }
            .padding()
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    .foregroundColor(configuration.isOn ? .blue : .gray)
                configuration.label
            }
        }
    }
}
