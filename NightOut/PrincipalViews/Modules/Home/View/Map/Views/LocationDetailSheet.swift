import SwiftUI
import Kingfisher

struct LocationDetailSheet: View {
    var selectedLocation: LocationModel
    var openMaps: () -> Void // Closure para manejar el cierre
    
    @State private var loadFailed = false // Estado para rastrear fallos
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    if loadFailed {
                        placeholderImage
                    } else {
                        if let imageUrl = selectedLocation.image {
                            KFImage.url(URL(string: imageUrl))
                                .placeholder { ProgressView() } // Muestra un indicador mientras carga
                                .onSuccess { result in
                                    loadFailed = false
                                }
                                .onFailure { error in
                                    print(error)
                                    loadFailed = true
                                }
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200) // Ajusta el tamaño según sea necesario
                                .cornerRadius(10)
                                .padding(.bottom, 10)
                        } else {
                            placeholderImage
                        }
                    }
                    
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
    
    var placeholderImage: some View {
        Image("placeholder")
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 150) // Ajusta el tamaño según sea necesario
            .cornerRadius(10)
            .padding(.bottom, 10)
    }
}

