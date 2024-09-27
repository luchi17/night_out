import SwiftUI

struct MapFilterOptionsView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Categorías")) {
                    Toggle("Discotecas Abiertas Ahora", isOn: .constant(true))
                    Toggle("Discotecas Populares", isOn: .constant(false))
                }
                
                Section(header: Text("Distancia")) {
                    Slider(value: .constant(10), in: 1...100) {
                        Text("Distancia en Km")
                    }
                }
            }
            .navigationBarTitle("Filtros", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cerrar") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

