import SwiftUI

struct LocationDetailView: View {
    @Binding var selectedLocation: LocationModel?
    @State var annotationPosition: CGPoint
    
    var body: some View {
        // Colocar el banner sobre la ubicación de la discoteca seleccionada
        VStack {
            if let location = selectedLocation {
                Spacer()
                    .frame(height: annotationPosition.y - 100)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(location.name)
                            .font(.headline)
                            .padding(.bottom, 2)
                        Text(location.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        selectedLocation = nil // Ocultar el banner
                    }) {
                        Image(systemName: "xmark")
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
                .padding()
            }
        }
        .frame(width: UIScreen.main.bounds.width/2, height: UIScreen.main.bounds.width/2)
        .position(x: annotationPosition.x, y: annotationPosition.y - 50)
    }
}
