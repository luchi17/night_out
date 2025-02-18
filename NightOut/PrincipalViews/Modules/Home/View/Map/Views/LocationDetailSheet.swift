import SwiftUI

struct LocationDetailSheet: View {
    var selectedLocation: LocationModel
    var openMaps: () -> Void

#warning("PENDING: show correct placeholder image")
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    if let imageUrl = selectedLocation.image {
                        KingFisherImage(url: URL(string: imageUrl))
                            .centerCropped(width: 150, height: 150) {
                                Image("profile")
                            }
                            .cornerRadius(10)
                            .padding(.vertical, 30)
                    } else {
                        placeholderImage
                    }
                    
                    Text(selectedLocation.name)
                        .font(.headline)
                        .padding(.bottom, 2)
                    
                    if let endTime = selectedLocation.endTime, let startTime = selectedLocation.startTime {
                        Text("Horario: \(startTime) - \(endTime)")
                            .font(.subheadline)
                            .padding(.bottom, 10)
                    }
                    if let selectedTag = selectedLocation.selectedTag, selectedLocation.selectedTag != LocationSelectedTag.none {
                        Text("Etiqueta: \(selectedTag.title)")
                            .font(.subheadline)
                            .padding(.bottom, 10)
                    }
                    
                    Text("Asistentes que conoces: \(String(describing: selectedLocation.followingGoing))")
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
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .padding()
        .presentationDetents([.height(300), .medium])
        .presentationBackground(.regularMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
    
    var placeholderImage: some View {
        Image("profile")
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 150)
            .cornerRadius(10)
            .padding(.vertical, 30)
    }
}
