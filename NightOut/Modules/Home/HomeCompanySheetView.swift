import SwiftUI
import Combine

struct HomeCompanySheetView: View {
    
    var close: VoidClosure
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Image("logo_amarillo")
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .foregroundStyle(.white)
            
            Text("¡Bienvenido a NightOut Empresas!\n👤¡La digitalización del ocio!")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text("¿Cómo funciona NightOut?")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text("✨ NightOut te permite digitalizar tu negocio\n- Ve al perfil para ver las acciones disponibles. 🌟\n• Sube tus entradas desde el gestor de entradas. 🎟️\n  • En ventas podrás llevar la cuenta de los ingresos 🎶\n-Sube post para que la gente se familiarice contigo. 🏅\n- En el mapa saldrá tu local donde te podrás dar a conocer. 📍\n  • Disfruta de NightOut Empresa y lleva tu negocio a otro nivel. 👥\n-Cualquier consulta contacta con el corporativo@formatink.com")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Button(action: {
                close()
            }) {
                Text("¡Entendido!".uppercased())
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.grayColor)
                    .cornerRadius(25)
            }
            
            Spacer()
        }
        .padding(.all, 12)
        .background(
            Color.darkBlueColor
                .ignoresSafeArea()
        )
    }
    
    
    
}
