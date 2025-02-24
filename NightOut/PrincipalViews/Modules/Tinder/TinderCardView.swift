import SwiftUI

struct TinderCardView: View {
    
    @Binding var user: TinderUser
    
    @State private var heartScale: CGFloat = 1.0
    
    var userLikedTapped: InputClosure<String>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) { // Asegura que los elementos inferiores mantengan su posición
                // Imagen de fondo
                AsyncImage(url: URL(string: user.image)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } placeholder: {
                    Color.gray
                }
                .edgesIgnoringSafeArea([.bottom])
                
                VStack {
                    // Ícono de corazón
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            user.liked = true
                            heartScale = 1.5 // Agranda el corazón al presionar
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring()) {
                                heartScale = 1.0 // Vuelve a su tamaño normal
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                userLikedTapped(user.uid) // Elimina la tarjeta y carga la siguiente
                            }
                        }
                    }) {
                        Image(user.liked ? "heart_clicked" : "heart")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.red)
                            .scaleEffect(heartScale)
                    }
                    .padding(.bottom, 20)
                    
                    // Nombre del usuario
                    Text(user.name)
                        .font(.title)
                        .padding()
                        .background(Color.blackColor.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 32)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
