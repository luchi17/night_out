import SwiftUI
import Charts
import Firebase

struct CompareSellsView: View {
    
    @State private var entradasPorEvento: [String: Int] = [:]
    @State private var recaudacionPorEvento: [String: Float] = [:]
    
    @State private var loading: Bool = false
    @State private var toast: ToastType?
    
    @Binding var selectedEvents: [String]
    let onClose: VoidClosure
    
    init(selectedEvents: Binding<[String]>, onClose: @escaping VoidClosure) {
        self._selectedEvents = selectedEvents
        self.onClose = onClose
    }
    
    var body: some View {
        VStack {
            // Título
            Text("Comparativa de Eventos")
                .font(.system(size: 24, weight: .bold))
                .bold()
                .padding(.top, 30)
                .padding(.bottom, 15)
            
            if recaudacionPorEvento.values.allSatisfy({ $0 == 0 }) &&
                entradasPorEvento.values.allSatisfy({ $0 == 0 }) && !loading {
                
                Spacer()
                
                Text("No hay datos disponibles para estos eventos.")
                    .foregroundColor(Color.blackColor)
                    .font(.headline)
                
            } else {
                // Gráfico de Entradas Vendidas
                if !entradasPorEvento.isEmpty {
                    
                    Chart(entradasPorEvento.sorted(by: { $0.key < $1.key }), id: \.key) { event, count in
                        BarMark(
                            x: .value("Evento", event),
                            y: .value("Entradas", count)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 300)
                    .chartXAxis {
                        AxisMarks(position: .bottom) { value in
                            AxisValueLabel()
                                .foregroundStyle(Color.blackColor) // Etiquetas del eje X en negro
                            AxisGridLine()
                                .foregroundStyle(Color.blackColor)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel()
                                .foregroundStyle(Color.blackColor) // Etiquetas del eje Y en negro
                        }
                    }
                    
                    // Leyenda
                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                        Text("Entradas Vendidas")
                            .font(.caption)
                            .foregroundColor(Color.blackColor)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 4)
                }
                
                // Gráfico de Recaudación
                if !recaudacionPorEvento.isEmpty {
                    
                    Chart(recaudacionPorEvento.sorted(by: { $0.key < $1.key }), id: \.key) { event, total in
                        BarMark(
                            x: .value("Evento", event),
                            y: .value("Recaudación", total)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 300)
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(Color.blackColor) // Etiquetas del eje X en negro
                            AxisGridLine()
                                .foregroundStyle(Color.blackColor)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel()
                                .foregroundStyle(Color.blackColor) // Etiquetas del eje Y en negro
                        }
                    }
                    
                    // Leyenda
                    HStack {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("Recaudación (€)")
                            .font(.caption)
                            .foregroundColor(Color.blackColor)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Botón de regreso
            Button(action: {
                onClose()
            }) {
                Text("Regresar".uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .background(Color.grayColor)
                    .cornerRadius(25)
            }
            .padding(.top, 16)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 20)
        .showToast(
            error: (
                type: toast,
                showCloseButton: false,
                onDismiss: {
                    toast = nil
                }
            ),
            isIdle: loading
        )
        .edgesIgnoringSafeArea(.all)
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            loadEventData(selectedEvents: self.selectedEvents)
        }
    }
    
    private func loadEventData(selectedEvents: [String]) {
        guard let currentUserID = FirebaseServiceImpl.shared.getCurrentUserUid() else { return }
        
        loading = true
        
        let database = FirebaseServiceImpl.shared
            .getCompanyInDatabaseFrom(uid: currentUserID)
            .child("Entradas")
        
        database.observeSingleEvent(of: .value) { snapshot in
            var entradasTemp: [String: Int] = [:]
            var recaudacionTemp: [String: Float] = [:]
            
            for event in selectedEvents {
                entradasTemp[event] = 0
                recaudacionTemp[event] = 0.0
            }
            
            for fechaSnapshot in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                for eventoSnapshot in fechaSnapshot.children.allObjects as? [DataSnapshot] ?? [] {
                    let evento = eventoSnapshot.key
                    
                    if selectedEvents.contains(evento) {
                        let lastTicketNumber = eventoSnapshot.childSnapshot(forPath: "TicketsVendidos/lastTicketNumber").value as? Int ?? 0
                        
                        var totalIngresos: Float = 0.0
                        let ticketsVendidosSnapshot = eventoSnapshot.childSnapshot(forPath: "TicketsVendidos")
                        
                        entradasTemp[evento] = lastTicketNumber
                        
                        guard lastTicketNumber >= 1 else {
                            continue
                        }
                        
                        for i in 1...lastTicketNumber {
                            let ticketSnapshot = ticketsVendidosSnapshot.childSnapshot(forPath: "TICKET-\(i)")
                            let precioRaw = ticketSnapshot.childSnapshot(forPath: "precio").value
                            
                            let precio: Float = {
                                if let precioStr = precioRaw as? String {
                                    return Float(precioStr) ?? 0.0
                                }
                                if let precioNum = precioRaw as? NSNumber {
                                    return precioNum.floatValue
                                }
                                return 0.0
                            }()
                            
                            if precio > 0 {
                                totalIngresos += precio
                            }
                        }
                        
                        recaudacionTemp[evento] = totalIngresos
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.loading = false
                self.entradasPorEvento = entradasTemp
                self.recaudacionPorEvento = recaudacionTemp
                print(self.entradasPorEvento)
                print(self.recaudacionPorEvento)
            }
        } withCancel: { error in
            self.loading = false
            self.toast = .custom(.init(title: "", description: "Error al cargar datos: \(error.localizedDescription).", image: nil))
        }
    }
}
