import SwiftUI
import Combine

struct LeagueHelpView: View {
    
    var close: VoidClosure
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Color.darkBlueColor
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Imagen encima del título
                    Image("icono_liga")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Texto encima del título
                    Text("¡Compite y gana a tus amigos!")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .italic()
                        .padding(.bottom, 8)
                    
                    // Título del mensaje
                    Text("¿Cómo funcionan las ligas?")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Descripción o explicación
                    Text("""
                        - Crea una liga con tus amigos y compite.
                        - Al subir una foto pulsa el trofeo y selecciona una bebida para puntuar.
                        - La foto debe contener una bebida
                        - Al acabarse el tiempo cumple con lo apostado.
                        - La próxima liga comenzará 24 horas después de acabar la anterior.
                        """)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .padding(.bottom, 16)
                    
                    // Botón Aceptar
                    Button(action: {
                        close()
                    }) {
                        Text("Aceptar".uppercased())
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.grayColor)
                            .cornerRadius(25)
                    }
                    .padding(.top, 16)
                    
                }
            }
        }
        .padding(.all, 12)
        .frame(maxWidth: .infinity)
        .background(
            Color.darkBlueColor
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        )
    }
}
