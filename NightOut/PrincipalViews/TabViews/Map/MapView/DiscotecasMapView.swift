import SwiftUI
import MapKit

struct DiscotecasMapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = "Discoteca"
    @State private var showFilterOptions = false // Estado para mostrar el filtro
    
    var body: some View {
        ZStack {
            // Mapa que ocupa toda la pantalla
            MapView(region: $locationManager.region, annotations: locationManager.discotecas) { newRegion in
                            // Llamamos a la función de búsqueda con la nueva región
                            locationManager.region = newRegion
                            locationManager.fetchNearbyPlaces(query: searchText)
                        }
            .edgesIgnoringSafeArea(.horizontal)
            
            VStack {
                // Barra de búsqueda en la parte superior
                SearchBar(searchText: $searchText)
                    .padding(.top, 30)
                
                Spacer()
                
                // Botón "Filtrar" en la parte inferior
                Button(action: {
                    showFilterOptions.toggle() // Muestra las opciones de filtro
                }) {
                    Text("Filtrar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.bottom, 30) // Asegurar que esté a una distancia del borde inferior
            }
        }
        // Alert o acción relacionada con los filtros
        .sheet(isPresented: $showFilterOptions) {
            MapFilterOptionsView() // Aquí puedes definir una vista con tus opciones de filtro
        }
        .onChange(of: searchText) { newSearchTerm in
            locationManager.fetchNearbyPlaces(query: newSearchTerm)
        }
        .alert(isPresented: $locationManager.locationPermissionDenied) {
            Alert(
                title: Text("Permisos de Localización Denegados"),
                message: Text("Por favor, habilita los permisos de localización en los ajustes para poder buscar discotecas cercanas."),
                primaryButton: .default(Text("Abrir Ajustes"), action: {
                    if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettings)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
    }
}
