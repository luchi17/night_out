import SwiftUI
import MapKit
import Combine


struct SignupMapView: View {
    @State private var searchQuery = ""
    @StateObject private var locationManager = LocationManager.shared
    
    @Binding var locationModel: LocationModel
    @State var auxModel = LocationModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var position = MapCameraPosition.automatic
    @State private var isLoadingUserLocation = true
    
    var body: some View {
        ZStack {
            Map(position: $position) {
                Annotation(locationModel.name, coordinate: auxModel.coordinate.location) {
                    CustomAnnotationView(
                        club: locationModel,
                        selection: .constant(nil)
                    )
                }
                .tag(locationModel)
                
                Annotation("user", coordinate: locationManager.userRegion.center) {
                    UserAnnotationView()
                }
                .tag("user")
            }
            .edgesIgnoringSafeArea(.all)
            
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
                    locationModel = auxModel
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("GUARDAR")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blackColor) // Adjust as needed for your button style
                        .cornerRadius(25)
                        .shadow(radius: 4)
                }
                .padding(.horizontal, 20)
            }
        }
        .onChange(of: locationManager.locations, { oldValue, newValue in
            if let location = locationManager.locations.first {
                auxModel = location
            }
        })
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
        .onChange(of: auxModel, { oldValue, newValue in
            let region = MKCoordinateRegion(center: auxModel.coordinate.location,
                                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            position = MapCameraPosition.region(region)
        })
        .onChange(of: locationManager.userLocation, { oldValue, newValue in
            position = MapCameraPosition.region(locationManager.userRegion)
            isLoadingUserLocation = newValue.location.latitude == 0.0
        })
        .applyStates(
            error: nil,
            isIdle: isLoadingUserLocation
        )
    }
}
