import SwiftUI

struct MapFilterOptionsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFilter: MapFilterType?
    let filters = MapFilterType.allCases
    
    var filterSelected: InputClosure<MapFilterType>
    
    @State private var showOptions = false

    var body: some View {
        VStack {
            Spacer()

            // Opciones desplegables cuando el botón de filtrar es pulsado
            if showOptions {
                VStack(spacing: 2) {
                    Button(action: {
                        selectedFilter = .near
                        hideOptions()
                    }) {
                        
                        HStack(alignment: .center,spacing: 10) {
                            Text(MapFilterType.near.title)
                            Image(systemName: MapFilterType.near.image)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        selectedFilter = .people
                        hideOptions()
                    }) {
                        
                        HStack(alignment: .center, spacing: 10) {
                            Text(MapFilterType.people.title)
                            Image(systemName: MapFilterType.people.image)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
                .opacity(showOptions ? 1 : 0)  // Controla la opacidad
                .transition(.move(edge: .bottom).combined(with: .opacity)) // Combina movimiento con opacidad
                .animation(.easeInOut(duration: 0.3), value: showOptions)
            }
            
            // Botón de Filtrar con un tap gesture para mostrar el menú
            Button(action: {
                withAnimation {
                    showOptions.toggle()
                }
            }) {
                Text(showOptions ? "Cerrar" : "Filtrar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal)
    }
    
    private func hideOptions() {
            withAnimation(.easeInOut(duration: 0.2)) {
                showOptions = false
            }
        }
}

enum MapFilterType: CaseIterable {
    case near
    case people
    
    var title: String {
        switch self {
        case .near:
            return "Cerca de mi"
        case .people:
            return "Asistencia"
        }
    }
    
    var image: String {
        switch self {
        case .near:
            return "location.circle"
        case .people:
            return "person.3.fill"
        }
    }
}
