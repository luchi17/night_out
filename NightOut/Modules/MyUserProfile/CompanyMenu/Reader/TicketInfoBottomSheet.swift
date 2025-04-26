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
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Text("Información del Ticket")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Color.blackColor)
                Spacer()
            }
            .padding(.vertical, 20)
        
            VStack(alignment: .leading, spacing: 12) {
                Text("Nombre: \(ticket.nombre.uppercased())")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blackColor)
                
                Text("Tipo de Entrada: \(ticket.tipoEntrada.uppercased())")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blackColor)
                
                Text("Correo: \(ticket.correo)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blackColor)
                
                Text("Precio: \(ticket.precio) €")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blackColor)
                
                Text("Fecha: \(ticket.fecha.uppercased())")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blackColor)
            }
            
            Spacer()
            
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.85).ignoresSafeArea())
    }
}
