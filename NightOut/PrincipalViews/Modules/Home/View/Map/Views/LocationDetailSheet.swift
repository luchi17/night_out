import SwiftUI

struct LocationDetailSheet: View {
    var selectedLocation: LocationModel
    var openMaps: () -> Void // Closure para manejar el cierre

    var body: some View {
        
        VStack {
            ScrollView {
                VStack {
                    // Imagen de la discoteca con un placeholder
                    Image("placeholder")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(10)
                        .padding(.bottom, 10)

                    Text(selectedLocation.name)
                        .font(.headline)
                        .padding(.bottom, 2)

                    Text(selectedLocation.description ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)

                    Text("Más detalles sobre la discoteca...")
                        .padding(.bottom, 10)

                    ForEach(0..<5, id: \.self) { _ in
                        Text("Información adicional sobre la discoteca")
                            .padding(.bottom, 5)
                    }
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)

            VStack {
                Button(action: {
                    openMaps()
                }) {
                    Text("Navegar a esta ubicación")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.bottom, 30)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

