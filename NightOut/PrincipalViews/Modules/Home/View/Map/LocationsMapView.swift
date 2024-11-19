import SwiftUI
import MapKit
import Combine

struct LocationsMapView: View {
    @State private var annotationPosition: CGPoint = .zero // Posición de la anotación seleccionada
    @State private var showingDetail = false
    @State private var showingListView = false
    
    private let openMapsPublisher = PassthroughSubject<(Double, Double), Never>()
    private let filterSelectedPublisher = PassthroughSubject<MapFilterType, Never>()
    private let searchSpecificLocationPublisher = PassthroughSubject<Void, Never>()
    private let regionChangedPublisher = PassthroughSubject<MKCoordinateRegion, Never>()
    private let locationInListSelectedPublisher = PassthroughSubject<LocationModel, Never>()
    private let viewDidLoadPublisher = CurrentValueSubject<Void, Never>(())
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
                region: Binding(
                        get: { viewModel.locationManager.region ?? viewModel.locationManager.userRegion },
                        set: { viewModel.locationManager.region = $0 }),
                locations: viewModel.filteredLocations.isEmpty ? $viewModel.allClubsModels : $viewModel.filteredLocations,
                onSelectLocation: { location, position in
                    viewModel.selectedMarkerLocation = location
                    annotationPosition = position //CLEAN?
                },
                forceUpdateView: viewModel.forceUpdateMapView
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Barra de búsqueda en la parte superior
                SearchBar(
                    searchText: $viewModel.searchQuery,
                    onSearch: searchSpecificLocationPublisher.send,
                    forceUpdateView: $viewModel.forceUpdateMapView
                )
                .padding()
                
                Spacer()
                
                MapFilterOptionsView(filterSelected: filterSelectedPublisher.send)
            }
        }
        .showToast(
            error: (type: viewModel.toastError, showCloseButton: true, onDismiss: { }),
            isIdle: viewModel.loading
        )
        .sheet(isPresented: $showingListView) {
            LocationsListView(
                locations: $viewModel.filteredLocations,
                onLocationSelected: { locationModel in
                    viewModel.selectedFilter = nil
                    locationInListSelectedPublisher.send(locationModel)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingDetail) {
            if let location = viewModel.selectedMarkerLocation {
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
        .onChange(of: viewModel.selectedMarkerLocation, {
            showingDetail = viewModel.selectedMarkerLocation != nil // Mostrar la sheet cuando se selecciona una discoteca
        })
        .onChange(of: viewModel.selectedFilter, {
            showingListView = viewModel.selectedFilter != nil // Mostrar la sheet cuando se selecciona un filtro
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
