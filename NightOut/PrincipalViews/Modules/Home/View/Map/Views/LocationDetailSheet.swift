import SwiftUI
import Kingfisher

struct LocationDetailSheet: View {
    var selectedLocation: LocationModel
    var openMaps: () -> Void
    
    @State private var loadFailed = false

#warning("PENDING: show correct placeholder image")
    
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
                                .frame(width: 150, height: 150)
                                .cornerRadius(10)
                                .padding(.vertical, 30)
                        } else {
                            placeholderImage
                        }
                    }
                    
                    Text(selectedLocation.name)
                        .font(.headline)
                        .padding(.bottom, 2)
                    
                    if let endTime = selectedLocation.endTime, let startTime = selectedLocation.startTime {
                        Text("Horario: \(startTime) - \(endTime)")
                            .font(.subheadline)
                            .padding(.bottom, 10)
                    }
                    if selectedLocation.selectedTag != LocationSelectedTag.none {
                        Text("Etiqueta: \(String(describing: selectedLocation.selectedTag?.title))")
                            .font(.subheadline)
                            .padding(.bottom, 10)
                    }
                    
                    Text("Asistentes: \(String(describing: selectedLocation.usersGoing))")
                        .font(.subheadline)
                        .padding(.bottom, 10)
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
            .frame(width: 150, height: 150)
            .cornerRadius(10)
            .padding(.vertical, 30)
    }
}
