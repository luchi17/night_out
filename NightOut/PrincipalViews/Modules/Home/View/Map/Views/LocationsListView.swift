import SwiftUI

struct LocationsListView: View {
    @Binding var locations: [LocationModel]
    var onLocationSelected: InputClosure<LocationModel>
    
    var body: some View {
        List {
            ForEach(locations) { location in
                HStack(spacing: 12) {
                    if let imageUrl = location.image {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(10)
                            
                        } placeholder: {
                            placeholderImage
                        }
                    } else {
                        placeholderImage
                    }
                    
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer() // Para empujar el contenido hacia la izquierda
                }
                .frame(maxWidth: .infinity) // Ocupa todo el ancho
                .background(Color.grayColor.opacity(0.5))
                .cornerRadius(10)
                .shadow(color: .grayColor.opacity(0.4), radius: 5, x: 0, y: 3)
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
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(10)
    }
    
}
