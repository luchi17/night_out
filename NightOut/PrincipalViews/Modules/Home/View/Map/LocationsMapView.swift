import SwiftUI
import MapKit
import Combine

struct LocationsMapView: View {
    @State private var showingList: Bool = false
    @State private var showingDetail: Bool = false
    @State private var showNavigationAlert = false
    
    private let openMapsPublisher = PassthroughSubject<(Double, Double), Never>()
    private let openAppleMapsPublisher = PassthroughSubject<(CLLocationCoordinate2D, String?), Never>()
    private let filterSelectedPublisher = PassthroughSubject<MapFilterType, Never>()
    private let locationInListSelectedPublisher = PassthroughSubject<LocationModel, Never>()
    private let goToProfilePublisher = PassthroughSubject<LocationModel, Never>()
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    @ObservedObject var viewModel: LocationsMapViewModel
    let presenter: LocationsMapPresenter
    
    @State private var scene: MKLookAroundScene?
    
    init(
        presenter: LocationsMapPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    @State private var position = MapCameraPosition.automatic
    
    var body: some View {
        Map(position: $position, selection: $viewModel.selectedMarkerLocation) {
            Annotation("", coordinate: viewModel.locationManager.userRegion.center) {
                UserAnnotationView()
            }
            .tag("user")
            
            ForEach(viewModel.allClubsModels) { club in
                Annotation(club.name, coordinate: club.coordinate.location) {
                    if viewModel.selectedMarkerFromList == club {
                        CustomAnnotationView(
                            club: club,
                            selection: $viewModel.selectedMarkerFromList
                        )
                    } else {
                        CircleImage(
                            imageUrl: club.image,
                            size: viewModel.selectedMarkerLocation == club ? 55 : 45,
                            border: true
                        )
                    }
                }
                .tag(club)
            }
        }
        .overlay(alignment: .top, content: {
            MapFilterOptionsView(
                filterSelected: { filter in
                    filterSelectedPublisher.send(filter)
                    showingList = true
                }
            )
            .padding(.top, 10)
            
        })
        .onChange(of: viewModel.selectedMarkerLocation) { oldValue, newValue in
            //Resetear ubi de lista cuando se selecciona un nuevo item en el mapa
            if let oldValue = oldValue, oldValue != newValue {
                viewModel.selectedMarkerFromList = nil
            }
            if let selectedMarkerLocation = viewModel.selectedMarkerLocation {
                let newRegion = MKCoordinateRegion(center: selectedMarkerLocation.coordinate.location,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                
                withAnimation(.easeInOut(duration: 1.0)) { // Duración de la animación en segundos
                    position = MapCameraPosition.region(newRegion)
                    showingDetail = true
                }
            }
        }
        .onChange(of: viewModel.selectedMarkerFromList) { oldValue, newValue in
            if let selectedMarkerLocation = viewModel.selectedMarkerFromList {
                let newRegion = MKCoordinateRegion(center: selectedMarkerLocation.coordinate.location,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                
                withAnimation(.easeInOut(duration: 1.0)) {
                    position = MapCameraPosition.region(newRegion)
                }
            }
        }
        .onChange(of: showNavigationAlert, { old, showNavigationAlert in
            if !showNavigationAlert {
                viewModel.selectedMarkerLocation = nil
            }
        })
        .sheet(isPresented: $showingDetail, onDismiss: {
            if !showNavigationAlert {
                viewModel.selectedMarkerLocation = nil
            }
        }) {
            if let location = viewModel.selectedMarkerLocation {
                LocationDetailSheet(
                    selectedLocation: location,
                    openMaps: {
                        showNavigationAlert = true
                    },
                    goToProfile: { profile in
                        showingDetail = false
                        goToProfilePublisher.send(profile)
                    }
                )
                .presentationDetents([.fraction(0.45), .fraction(0.6)])
            }
        }
        .sheet(isPresented: $showingList, onDismiss: {
           
        }) {
            LocationClubsSheetView(
                locations: $viewModel.currentShowingLocationList,
                selectedLocation: { location in
                    showingList = false
                    locationInListSelectedPublisher.send(location)
                }
            )
        }
        .alert(isPresented: $viewModel.locationManager.locationPermissionDenied) {
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
        .alert("Abrir ubicación", isPresented: $showNavigationAlert) {
            Button("Apple Maps") {
                if let selectedMarkerLocation = viewModel.selectedMarkerLocation {
                    openAppleMapsPublisher.send(
                        (selectedMarkerLocation.coordinate.location, selectedMarkerLocation.name)
                        )
                }
            }
            Button("Google Maps") {
                if let selectedMarkerLocation = viewModel.selectedMarkerLocation {
                    openMapsPublisher.send(
                        (selectedMarkerLocation.coordinate.location.latitude, selectedMarkerLocation.coordinate.location.longitude)
                    )
                }
               
            }
            Button("Close", role: .cancel) {}
        } message: {
            Text("Choose an app to open the location.")
        }
        .onAppear {
            // Al aparecer la vista, centrar el mapa en la ubicación del usuario
            position = MapCameraPosition.region(viewModel.locationManager.userRegion)
            viewDidLoadPublisher.send()
        }
        .showToast(
            error: (
                type: viewModel.toastError,
                showCloseButton: false,
                onDismiss: {
                    viewModel.toastError = nil
                }
            ),
            isIdle: viewModel.loading
        )
    }
    
    private func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene? {
        let lookAroundScene = MKLookAroundSceneRequest(coordinate: coordinate)
        return try await lookAroundScene.scene
    }
}

private extension LocationsMapView {
    
    func bindViewModel() {
        let input = LocationsMapPresenterImpl.ViewInputs(
            openMaps: openMapsPublisher.eraseToAnyPublisher(),
            openAppleMaps: openAppleMapsPublisher.eraseToAnyPublisher(),
            onFilterSelected: filterSelectedPublisher.eraseToAnyPublisher(),
            locationInListSelected: locationInListSelectedPublisher.eraseToAnyPublisher(),
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher(),
            goToProfile: goToProfilePublisher.eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}


struct LocationClubsSheetView: View {
    @Binding var locations: [LocationModel]
    var selectedLocation: InputClosure<LocationModel>
    
    var body: some View {
        LocationsListView(
            locations: $locations,
            onLocationSelected: selectedLocation
        )
        .padding(.top, 20)
        .presentationDetents([.large])
        .presentationBackground(.regularMaterial)
    }
}

