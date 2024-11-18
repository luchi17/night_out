import SwiftUI

// Remove ?
struct LocationDetailView: View {
    @Binding var selectedLocation: LocationModel?
    @State var annotationPosition: CGPoint
    var onDismiss: () -> Void // Closure para manejar el cierre

    var body: some View {
        HStack {
            content
            VStack {
                Button(action: {
                    onDismiss() // Cierra el banner
                }) {
                    Image(systemName: "xmark")
                        .padding(.trailing)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
        .padding(.horizontal, 40)
        .frame(maxHeight: 300)
    }
    
    // Contenido principal de la vista
    private var content: some View {
        VStack {
            if let selectedLocation = selectedLocation {
                // Imagen de la discoteca con un placeholder
                Image("placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(10)
                    .padding()

                Text(selectedLocation.name)
                    .font(.headline)
                    .padding(.bottom, 2)
                Text(selectedLocation.description ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)

                Text("Más detalles sobre la discoteca...")
                    .padding(.bottom, 10)

                ForEach(0..<10, id: \.self) { _ in
                    Text("Contenido adicional aquí")
                        .padding(.bottom, 5)
                }
            }
        }
    }
}
