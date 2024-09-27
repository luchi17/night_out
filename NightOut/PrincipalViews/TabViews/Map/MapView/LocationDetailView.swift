import SwiftUI

struct LocationDetailView: View {
    let location: LocationModel

    var body: some View {
        NavigationView {
            VStack {
                Text(location.name)
                    .font(.largeTitle)
                    .padding()

                Text(location.description)
                    .font(.body)
                    .padding()

                Spacer()
            }
            .navigationBarTitle("Detalles", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cerrar") {
                // Acción para cerrar
            })
        }
    }
}
