import SwiftUI
import MapKit
import Combine


struct SignupMapView: View {
    @State private var searchQuery = ""
    @StateObject private var locationManager = LocationManager.shared
    
    @Binding var locationModel: LocationModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Mapa que ocupa toda la pantalla
//            MapView(
//                region: Binding(
//                    get: { locationManager.region ?? locationManager.userRegion },
//                    set: { _ in }),
//                locations: $locationManager.locations,
//                onSelectLocation: { _ , _ in },
//                forceUpdateView: true
//            )
//            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Barra de búsqueda en la parte superior
                SearchBar(
                    searchText: $searchQuery,
                    onSearch: {
                        locationManager.searchLocation(searchQuery: searchQuery)
                    }
                )
                .padding()
                
                Spacer()
                
                Button(action: {
                    if let location = locationManager.locations.first {
                        locationModel = location
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("SAVE")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue) // Adjust as needed for your button style
                        .cornerRadius(25)
                        .shadow(radius: 4)
                }
                .padding(.horizontal, 20)
            }
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
