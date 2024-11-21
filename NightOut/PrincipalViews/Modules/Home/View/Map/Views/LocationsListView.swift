import SwiftUI
import Kingfisher

struct LocationsListView: View {
    @Binding var locations: [LocationModel]
    var onLocationSelected: InputClosure<LocationModel>
    
#warning("PENDING: show correct placeholder image and also in case of error")
    
    var body: some View {
        List {
            ForEach(locations) { location in
                HStack(spacing: 12) {
                    if let imageUrl = location.image {
                        KFImage.url(URL(string: imageUrl))
                            .placeholder { ProgressView() } // Muestra un indicador mientras carga
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(10)
                    } else {
                        placeholderImage
                    }
                    
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer() // Para empujar el contenido hacia la izquierda
                }
                .frame(maxWidth: .infinity) // Ocupa todo el ancho
                .background(Color.gray.opacity(0.5))
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 3)
                .onTapGesture {
                    onLocationSelected(location)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
            .padding(.vertical, 5)
        }
        .scrollIndicators(.hidden)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 12)
    }
    
    var placeholderImage: some View {
        Image("placeholder")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60, height: 60)
            .cornerRadius(10)
    }
    
}
