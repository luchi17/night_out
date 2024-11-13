import SwiftUI


struct FeedView: View {
    let posts = ["Post 1", "Post 2", "Post 3"] // Reemplaza con datos reales
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(posts, id: \.self) { post in
                    VStack {
                        // Contenido del post
                        Text(post) // Reemplaza con tu contenido real de publicación
                            .font(.headline)
                        Image(systemName: "photo.fill") // Ejemplo de imagen del post
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 20)
    }
}

