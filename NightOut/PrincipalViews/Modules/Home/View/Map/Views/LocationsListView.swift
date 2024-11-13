import SwiftUI

struct LocationsListView: View {
    @Binding var locations: [LocationModel]
    var onLocationSelected: InputClosure<LocationModel>
    
    var body: some View {
        List(locations) { location in
            
            VStack {
                HStack(spacing: 10) {
                    Image(location.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .cornerRadius(10)
                    
                    Text(location.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                }
                .padding(.leading, 10)
                Spacer()
            }
            .background(Color.gray.opacity(0.2))
            .padding(.horizontal)
            .padding(.bottom, 8)
            .onTapGesture {
                onLocationSelected(location)
            }
        }
    }
    
}
