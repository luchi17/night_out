import SwiftUI

struct TinderCardView: View {
    
    @Binding var user: TinderUser
    @State private var userLiked: Bool = false
    @State private var offset: CGSize = .zero
    
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
                        userLiked = true
                        userLikedTapped(user.uid)
                    }) {
                        Image(userLiked ? "heart_clicked" : "heart")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.red)
                    }
                    .padding(.bottom, 20)
                
                    // Nombre del usuario
                    Text(user.name)
                        .font(.title)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 32)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
