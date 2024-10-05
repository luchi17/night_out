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
                VStack(spacing: 10) {
                    Button(action: {
                        selectedFilter = .near
                        showOptions = false
                    }) {
                        Text("Cerca de mí")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        selectedFilter = .people
                        showOptions = false
                    }) {
                        Text("Distancia")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .transition(.move(edge: .bottom))
                .padding(.bottom, 10)
            }
            
            // Botón de Filtrar con un tap gesture para mostrar el menú
            Button(action: {
                withAnimation {
                    showOptions.toggle() // Alterna la visibilidad del menú con animación
                }
            }) {
                Text("Filtrar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
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
            return "arrow.up.and.down.circle"
        }
    }
}
