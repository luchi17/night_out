import SwiftUI
import MapKit
import Combine

struct LocationsMapView: View {
    @State private var annotationPosition: CGPoint = .zero // Posición de la anotación seleccionada
    @State private var filteredLocations: [LocationModel] = [] // Localizaciones filtradas
    @State private var showingDetail = false
    
    private let openMapsPublisher = PassthroughSubject<(Double, Double), Never>()
    private let filterSelectedPublisher = PassthroughSubject<MapFilterType, Never>()
    private let searchSpecificLocationPublisher = PassthroughSubject<Void, Never>()
    private let regionChangedPublisher = PassthroughSubject<MKCoordinateRegion, Never>()
    private let locationSelectedPublisher = PassthroughSubject<LocationModel, Never>()
    private let viewDidLoadPublisher = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    @ObservedObject var viewModel: LocationsMapViewModel
    let presenter: LocationsMapPresenter
    
    init(
        presenter: LocationsMapPresenter
    ) {
        self.presenter = presenter
        viewModel = presenter.viewModel
        bindViewModel()
    }
    
    var body: some View {
        ZStack {
            // Mapa que ocupa toda la pantalla
            MapView(
                region: $viewModel.locationManager.region,
                locations: filteredLocations.isEmpty ? $viewModel.locationManager.locations : $filteredLocations,
                onSelectLocation: { location, position in
                    viewModel.selectedLocation = location // Guardar la discoteca seleccionada
                    annotationPosition = position //CLEAN?
                },
                onRegionChange: regionChangedPublisher.send
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Barra de búsqueda en la parte superior
                SearchBar(searchText: $viewModel.searchQuery, onSearch: searchSpecificLocationPublisher.send)
                .padding()
                
                Spacer()
                
                if !viewModel.filteredLocations.isEmpty {
                    LocationsListView(
                        locations: $viewModel.filteredLocations,
                        onLocationSelected: locationSelectedPublisher.send
                    )
                }
                
                MapFilterOptionsView(filterSelected: filterSelectedPublisher.send)
            }
        }
        .showToast(
            error: (type: viewModel.toastError, showCloseButton: true, onDismiss: { }),
            isIdle: viewModel.loading
        )
        .sheet(isPresented: $showingDetail) {
            if let location = viewModel.selectedLocation {
                LocationDetailSheet(
                    selectedLocation: location,
                    openMaps: {
                        openMapsPublisher.send((location.coordinate.latitude, location.coordinate.longitude))
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: viewModel.selectedLocation, {
            showingDetail = viewModel.selectedLocation != nil // Mostrar la sheet cuando se selecciona una discoteca
        })
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
            viewDidLoadPublisher.send()
        }
    }
    
    private func searchLocation() {
        if viewModel.searchQuery.isEmpty {
            filteredLocations = []
        } else {
            filteredLocations = viewModel.locationManager.locations.filter {
                $0.name.lowercased().contains(viewModel.searchQuery.lowercased())
            }
            
        }
    }
}

private extension LocationsMapView {
    
    func bindViewModel() {
        let input = LocationsMapPresenterImpl.ViewInputs(
            openMaps: openMapsPublisher.eraseToAnyPublisher(),
            onFilterSelected: filterSelectedPublisher.eraseToAnyPublisher(),
            locationBarSearch: searchSpecificLocationPublisher.eraseToAnyPublisher(),
            regionChanged: regionChangedPublisher.eraseToAnyPublisher(),
            locationSelected: locationSelectedPublisher.eraseToAnyPublisher(),
            viewDidLoad: viewDidLoadPublisher.first().eraseToAnyPublisher()
        )
        presenter.transform(input: input)
    }
}
