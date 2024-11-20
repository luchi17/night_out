import SwiftUI
import MapKit
import Combine

struct LocationsMapView: View {
    @State private var isSheetPresented: Bool = true
    
    private let openMapsPublisher = PassthroughSubject<(Double, Double), Never>()
    private let filterSelectedPublisher = PassthroughSubject<MapFilterType, Never>()
    private let searchSpecificLocationPublisher = PassthroughSubject<Void, Never>()
    private let regionChangedPublisher = PassthroughSubject<MKCoordinateRegion, Never>()
    private let locationInListSelectedPublisher = PassthroughSubject<LocationModel, Never>()
    private let viewDidLoadPublisher = CurrentValueSubject<Void, Never>(())
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
        ZStack {
            Map(position: $position, selection: Binding(get: {
                return viewModel.selectedMarkerLocation
            }, set: { value in
                viewModel.selectedMarkerLocation = value
            })) {
                Annotation("", coordinate: viewModel.locationManager.userRegion.center) {
                    UserAnnotationView()
                }
                
                ForEach(viewModel.allClubsModels) { club in
                    Annotation(club.name, coordinate: club.coordinate.location) {
                        CustomAnnotationView()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if viewModel.selectedMarkerLocation != nil {
                    LookAroundPreview(scene: $scene, allowsNavigation: false, badgePosition: .bottomTrailing)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .safeAreaPadding(.bottom, 40)
                        .padding(.horizontal, 20)
                }
            }
            .overlay(alignment: .topTrailing) {
                MapFilterOptionsView(filterSelected: filterSelectedPublisher.send)
            }
        }
        .onChange(of: viewModel.selectedMarkerLocation) {
            if let selectedMarkerLocation = viewModel.selectedMarkerLocation {
                Task {
                    scene = try? await fetchScene(for: selectedMarkerLocation.coordinate.location)
                }
                
                let newRegion = MKCoordinateRegion(center: selectedMarkerLocation.coordinate.location,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                position = MapCameraPosition.region(newRegion)
            }
            isSheetPresented = viewModel.selectedMarkerLocation == nil
            
        }
        .sheet(isPresented: $isSheetPresented) {
            SheetView(
                search: $viewModel.searchQuery,
                searchResults: Binding(get: {
                    return viewModel.filteredLocations.isEmpty ? viewModel.allClubsModels : viewModel.filteredLocations
                }, set: { _ in }),
                onSearch: searchSpecificLocationPublisher.send,
                selectedLocation: locationInListSelectedPublisher.send
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
        
        .onAppear {
            // Al aparecer la vista, centrar el mapa en la ubicación del usuario
            position = MapCameraPosition.region(viewModel.locationManager.userRegion)
            viewDidLoadPublisher.send()
        }
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
            onFilterSelected: filterSelectedPublisher.eraseToAnyPublisher(),
            locationBarSearch: searchSpecificLocationPublisher.eraseToAnyPublisher(),
            locationInListSelected: locationInListSelectedPublisher.eraseToAnyPublisher(),
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}


struct SheetView: View {
    @Binding var search: String
    
    @Binding var searchResults: [LocationModel]
    var onSearch: VoidClosure
    var selectedLocation: InputClosure<LocationModel>
    
    var body: some View {
        VStack {
            // 1
            //            HStack {
            //                Image(systemName: "magnifyingglass")
            //                TextField("Search for a bar", text: $search)
            //                    .autocorrectionDisabled()
            //                    .onSubmit {
            //                        onSearch()
            //                    }
            //            }
            //            .padding(12)
            //            .background(.gray.opacity(0.1))
            //            .cornerRadius(8)
            //            .foregroundColor(.primary)
            
            SearchBar(
                searchText: $search,
                onSearch: onSearch
            )
            
            Spacer()
            
            LocationsListView(
                locations: $searchResults,
                onLocationSelected: selectedLocation
            )
        }
        .padding()
        .interactiveDismissDisabled()
        .presentationDetents([.height(100), .large])
        .presentationBackground(.regularMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
}

