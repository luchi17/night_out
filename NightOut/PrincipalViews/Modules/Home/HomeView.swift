import SwiftUI

struct HomeView: View {
    
    @State private var selectedTab: HomeSelectedTab = .feed
    
    var body: some View {
        VStack {
            // Parte superior de la pantalla
            HStack {
                // Botón de perfil
                Button(action: {
                    
                }) {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                }
                .padding(.leading)
                
                Spacer()
                
                // Logo de la aplicación
                Image("appLogo") // Reemplaza con el nombre de tu imagen de logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                
                Spacer()
                
                // Botón de notificaciones
                Button(action: {
                    
                }) {
                    Image(systemName: "bell.fill")
                        .font(.title)
                }
                .padding(.trailing)
            }
            .padding(.top)
            
            Picker(selectedTab: $selectedTab)
            
            if selectedTab == .map {
                //                    LocationsMapView()
                EmptyView()
                    .background(.blue)
            } else {
                FeedView()
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
    }
}


struct Picker: View {
    
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
                            .foregroundColor(selectedTab == .feed ? .white : .gray)
                        Text("Feed")
                            .foregroundColor(selectedTab == .feed ? .white : .gray)
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
                            .foregroundColor(selectedTab == .map ? .white : .gray)
                        Text("Mapa")
                            .foregroundColor(selectedTab == .map ? .white : .gray)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity) // Ocupa el mismo espacio
                    .padding()
                    .background(selectedTab == .map ? Color.yellow : Color.clear)
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 50)
        .padding(.top, 20)
    }
}


// Vista de Feed (tipo Instagram)
struct FeedView: View {
    let posts = ["Post 1", "Post 2", "Post 3"] // Reemplaza con datos reales
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(posts, id: \.self) { post in
                    VStack {
                        // Contenido del post
                        Text(post) // Reemplaza con tu contenido real de publicación
                            .font(.headline)
                        Image(systemName: "photo.fill") // Ejemplo de imagen del post
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
            }
            .padding()
        }
    }
}
