import SwiftUI
import Combine

struct AddPostClubsList: View {
    @Binding var locations: [AddPostLocationModel]
    var onLocationSelected: InputClosure<AddPostLocationModel>
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Elige un club")
                .foregroundColor(.blackColor)
                .font(.system(size: 16))
                .bold()
                .padding(.top, 20)
                .padding(.bottom, 12)
            
            List {
                ForEach(locations) { location in
                    HStack(spacing: 12) {
                        Text(location.name)
                            .font(.system(size: 14))
                            .foregroundColor(.blackColor)
                        
                        Spacer() // Para empujar el contenido hacia la izquierda
                    }
                    .frame(maxWidth: .infinity) // Ocupa todo el ancho
                    .padding(.all, 8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .onTapGesture {
                        onLocationSelected(location)
                    }
                    .listRowBackground(Color.white)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }
            }
            .padding(.bottom, 10)
            .scrollIndicators(.hidden)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .padding(.horizontal, 20)
    }
}

struct AddPostLocationModel: Identifiable {
    let id = UUID()
    var name: String
    var uid: String
    var location: String
}


struct ClubSelectionAlert: View {
    
    var onTypeSelected: InputClosure<AddPostLocationSelection>
    
    var body: some View {
        HStack {
            
            VStack(alignment: .leading, spacing: 20) {
                
                Text("Localización")
                    .font(.system(size: 16))
                    .foregroundColor(.blackColor)
                    .bold()
                    .padding(.top, 12)
                
                Button {
                    onTypeSelected(AddPostLocationSelection.myLocation)
                } label: {
                    
                    Text("Tu ubicación")
                        .font(.system(size: 14))
                        .foregroundColor(.blackColor)
                }
                Button {
                    onTypeSelected(AddPostLocationSelection.clubs)
                } label: {
                    Text("Clubs")
                        .font(.system(size: 14))
                        .foregroundColor(.blackColor)
                }
            }
            
            Spacer()
            
        }
        .padding(.leading, 20)
    }
}


enum AddPostLocationSelection {
    case myLocation
    case clubs
}
