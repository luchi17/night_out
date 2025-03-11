import SwiftUI

struct TicketQRReaderInfo {
    let nombre: String
    let tipoEntrada: String
    let correo: String
    let precio: String
    let fecha: String
}

struct TicketInfoBottomSheet: View {
    let ticket: TicketQRReaderInfo
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Información del Ticket")
                .font(.headline)
                .padding()

            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre: \(ticket.nombre)").bold()
                Text("Tipo de Entrada: \(ticket.tipoEntrada)")
                Text("Correo: \(ticket.correo)")
                Text("Precio: \(ticket.precio) €")
                Text("Fecha: \(ticket.fecha)")
            }
            .padding()

            Button("Cerrar") {
                isPresented = false
            }
            .padding()
        }
        .padding()
    }
}
