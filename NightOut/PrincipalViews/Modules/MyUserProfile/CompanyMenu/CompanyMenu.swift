import SwiftUI

struct CompanyMenu: View {
    
    @Binding var selection: CompanyMenuSelection?
    @Binding var showSheet: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                Button(action: {
                    selection = .lectorEntradas
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.lectorEntradas.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {
                    selection = .ventas
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.ventas.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {
                    selection = .metodosDePago
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.metodosDePago.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {
                    selection = .gestorEventos
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.gestorEventos.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {
                    selection = .publicidad
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.publicidad.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {
                    selection = .datosEvento
                    showSheet = false
                }) {
                    Text(CompanyMenuSelection.datosEvento.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
        }
        .padding(.all, 20)
        .background(Color.grayColor)
        .frame(maxWidth: 210, alignment: .leading)
    }
}

enum CompanyMenuSelection: Identifiable {
    
    var id: String { title }
    
    case lectorEntradas
    case ventas
    case metodosDePago
    case gestorEventos
    case publicidad
    case datosEvento
    
    var title: String {
        switch self {
        case .lectorEntradas:
            return "Lector de entradas"
        case .ventas:
            return "Ventas"
        case .metodosDePago:
            return "Métodos de pago"
        case .gestorEventos:
            return "Gestor eventos"
        case .publicidad:
            return "Publicidad"
        case .datosEvento:
            return "Datos del evento"
        }
    }
}

