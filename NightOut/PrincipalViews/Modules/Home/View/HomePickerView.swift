import SwiftUI

struct HomePickerView: View {
    
    @Binding var selectedTab: HomeSelectedTab
    
    var body: some View {
        ZStack {
            // Fondo para el selector, es un contenedor de los botones
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(radius: 5)
                .frame(height: 50)
            
            HStack {
                // Botón "Feed"
                Button(action: {
                    selectedTab = .feed
                }) {
                    HStack {
                        Image(systemName: "list.dash") // Imagen para Feed
                            .foregroundColor(selectedTab == .feed ? .white : .yellow)
                        Text("Feed")
                            .foregroundColor(selectedTab == .feed ? .white : .yellow)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity) // Ocupa el mismo espacio
                    .padding()
                    .background(selectedTab == .feed ? Color.yellow : Color.clear)
                    .cornerRadius(15)
                }
                
                // Botón "Mapa"
                Button(action: {
                    selectedTab = .map
                }) {
                    HStack {
                        Image(systemName: "map.fill") // Imagen para Mapa
                            .foregroundColor(selectedTab == .map ? .white : .yellow)
                        Text("Mapa")
                            .foregroundColor(selectedTab == .map ? .white : .yellow)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity) // Ocupa el mismo espacio
                    .padding()
                    .background(selectedTab == .map ? Color.yellow : Color.clear)
                    .cornerRadius(15)
                }
            }
        }
        .padding(.horizontal, 70)
        .padding(.bottom, 10)
        .frame(height: 50)
    }
}
