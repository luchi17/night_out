import SwiftUI
import Firebase
import FirebaseDatabase

struct GestionEconomicaView: View {
    
    @State private var entryTypeDetails: [String: (totalRevenue: Float, ticketCount: Int)] = [:]
    
    @State private var selectedCompareEvents = [String]()

    @State private var totalEntradas = 0
    @State private var totalIngresos: Float = 0.0
    
    @State private var selectedEvent: String = ""
    @State private var eventNames: [String] = []
    
    @State private var loading: Bool = false
    @State private var toast: ToastType?
    @State private var showCustomAlert: Bool = false
    
    let onClose: VoidClosure
    
    init(onClose: @escaping VoidClosure) {
        self.onClose = onClose
        selectedEvent = defaultSelection
        eventNames.append(defaultSelection)
    }
    
    private let defaultSelection = "Seleccione"
    
    var body: some View {
        ScrollView {
            VStack {
                
                HStack {
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color.white)
                    }
                }
                .padding(.trailing, 15)
                .padding(.top, 22)
                
                Text("Resumen de Ventas")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("SELECCIONE UN EVENTO")
                    .font(.headline)
                    .foregroundColor(Color.blue)
                    .padding()
                
                picker
                    .padding(.bottom, 30)
                
                // Tabla de comparaciones de eventos
                Button(action: {
                    selectedCompareEvents = eventNames.map { $0 }
                    showCustomAlert.toggle()
                    
                }) {
                    Text("Comparar eventos".uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .background(Color.grayColor)
                        .cornerRadius(25)
                }
                .padding(.bottom, 20)
                
                // Tabla de detalles del evento
                tableView
            }
            .padding(.horizontal, 20)
        }
        .clipShape(Rectangle())
        .scrollClipDisabled(false)
        .scrollIndicators(.hidden)
        .edgesIgnoringSafeArea(.bottom)
        .background(
            Color.blackColor.edgesIgnoringSafeArea(.all)
        )
        .sheet(isPresented: $showCustomAlert, content: {
            CustomSellsAlertView(
                title: "Selecciona eventos para comparar",
                options: eventNames.filter({ $0 != defaultSelection }),
                onSelection: { selected in
                if !selected.isEmpty {
                    // navigateToCompareEvents(selected)
                    selectedCompareEvents = selected
                } else {
                    self.toast = .custom(.init(title: "", description: "Selecciona al menos un evento.", image: nil))
                }
                
            },
             dismiss: { showCustomAlert.toggle() })
            .presentationDetents([.fraction(0.4), .medium, .large])
            
        })
        .onChange(of: selectedEvent) { oldValue, newValue in
            if selectedEvent != defaultSelection {
                for event in eventNames {
                    loadEventDetails(event)
                    loadEventEntryTypeDetails(event: event)
                }
            }
        }
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
        .onAppear {
            loadUniqueEvents()
        }
    }
    
    private var picker: some View {
        Picker("Evento", selection: $selectedEvent) {
            ForEach(eventNames, id: \.self) { type in
                Text(type)
                    .foregroundStyle(Color.blackColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .tag(type)
            }
        }
        .labelsHidden()
        .pickerStyle(MenuPickerStyle())
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(Color.blackColor)
        .accentColor(Color.blackColor)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white)
        )
        .onAppear {
            // Asegúrate de que la primera opción esté seleccionada si no hay ninguna
            if selectedEvent.isEmpty {
                selectedEvent = defaultSelection
            }
        }
    }
    
    private var tableView: some View {
        VStack {
            HStack {
                Text("Entradas")
                    .foregroundStyle(Color.blackColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Ingresos")
                    .foregroundStyle(Color.blackColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.bottom, 5)
            
            Divider()
                .frame(height: 1)
                .foregroundStyle(Color.grayColor)
            
            HStack {
                Text("\(totalEntradas)")
                    .foregroundStyle(Color.blackColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(String(format: "%.2f€", totalIngresos))
                    .foregroundStyle(Color.blackColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
                .frame(height: 15)
            
            HStack {
                Text("Tipo entrada")
                    .foregroundStyle(Color.blackColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Ventas")
                    .foregroundStyle(Color.blackColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.bottom, 5)
            
            ForEach(entryTypeDetails.keys.sorted(), id: \.self) { entryType in
                let data = entryTypeDetails[entryType]!
                
                HStack {
                    Text("\(entryType) (\(data.ticketCount))")
                        .foregroundStyle(Color.blackColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    Text(String(format: "%.2f€", data.totalRevenue))
                        .foregroundStyle(Color.blackColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
            }
           
        }
        .background(Color.white)
    }
    
    //Get names of events
    func loadUniqueEvents() {
        self.loading = true
        
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            self.toast = .custom(.init(title: "", description: "Usuario no autenticado.", image: nil))
            return
        }
        let db = FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: currentUserId)
        
        db.child("Entradas").observeSingleEvent(of: .value) { snapshot in
            var uniqueEvents = Set<String>()
            
            for case let fechaSnapshot as DataSnapshot in snapshot.children {
                for case let eventoSnapshot as DataSnapshot in fechaSnapshot.children {
                    let evento = eventoSnapshot.key
                    if !evento.isEmpty {
                        uniqueEvents.insert(evento)
                    }
                }
            }
            self.loading = false
            
            self.eventNames = Array(uniqueEvents)
            self.eventNames.insert(defaultSelection, at: 0)
            
        }
    }
    
    //Get names of events
    func loadEventDetails(_ event: String) {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            self.toast = .custom(.init(title: "", description: "Usuario no autenticado.", image: nil))
                return
        }
        
        let db = FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: currentUserId)
        
        db.child("Entradas").observeSingleEvent(of: .value) { snapshot in
            var totalIngresos: Float = 0.0
            var totalEntradas = 0
            
            for case let fechaSnapshot as DataSnapshot in snapshot.children {
                
                for case let eventoSnapshot as DataSnapshot in fechaSnapshot.children {
                    
                    let evento = eventoSnapshot.key
                    
                    if evento == event {
                        
                        let lastTicketNumber = eventoSnapshot.childSnapshot(forPath: "TicketsVendidos/lastTicketNumber").value as? Int ?? 0
                        totalEntradas = lastTicketNumber
                        
                        guard lastTicketNumber >= 1 else {
                            self.loading = false
                            return
                        }
                        
                        for i in 1...lastTicketNumber {
                            
                            let ticketSnapshot = eventoSnapshot.childSnapshot(forPath: "TicketsVendidos/TICKET-\(i)")
                            let ticketPrecioRaw = ticketSnapshot.childSnapshot(forPath: "precio").value
                            let ticketPrecio: Float
                            
                            if let ticketPrecioRaw = ticketPrecioRaw as? String {
                                ticketPrecio = Float(ticketPrecioRaw) ?? 0
                            } else if let ticketPrecioRaw = ticketPrecioRaw as? Double {
                                ticketPrecio = Float(ticketPrecioRaw)
                            } else if let ticketPrecioRaw = ticketPrecioRaw as? Float {
                                ticketPrecio = Float(ticketPrecioRaw)
                            } else {
                                ticketPrecio = 0
                            }
                            
                            if ticketPrecio > 0 {
                                totalIngresos += ticketPrecio
                            }
                        }
                    }
                }
            }
            
            self.totalIngresos = totalIngresos
            self.totalEntradas = totalEntradas
        }
    }
    
    //Get names of events
    private func loadEventEntryTypeDetails(event: String) {
        guard let currentUserId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            self.toast = .custom(.init(title: "", description: "Usuario no autenticado.", image: nil))
                return
            }

            loading = true
            entryTypeDetails.removeAll()

        let db = FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: currentUserId)
        
        db.child("Entradas").observeSingleEvent(of: .value) { snapshot in
                var eventFound = false
                var tempEntryTypeDetails: [String: (totalRevenue: Float, ticketCount: Int)] = [:]

                for fechaSnapshot in snapshot.children.allObjects as! [DataSnapshot] {
                    
                    for eventoSnapshot in fechaSnapshot.children.allObjects as! [DataSnapshot] {
                        
                        let eventName = eventoSnapshot.key
                        
                        if eventName == event {
                            
                            eventFound = true
                            
                            let ticketsVendidos = eventoSnapshot.childSnapshot(forPath: "TicketsVendidos")

                            for ticketSnapshot in ticketsVendidos.children.allObjects as! [DataSnapshot] {
                                
                                let ticketPrice = ticketSnapshot.childSnapshot(forPath: "precio").value as? String ?? "0.0"
                                let ticketPriceFloat = Float(ticketPrice) ?? 0.0
                                let entryType = ticketSnapshot.childSnapshot(forPath: "tipo de entrada").value as? String ?? ""

                                if !entryType.isEmpty && entryType != "Desconocido" {
                                    let current = tempEntryTypeDetails[entryType, default: (0, 0)]
                                    tempEntryTypeDetails[entryType] = (current.totalRevenue + ticketPriceFloat, current.ticketCount + 1)
                                }
                            }
                        }
                    }
                }

                if !eventFound || tempEntryTypeDetails.isEmpty {
                    self.toast = .custom(.init(title: "", description: "No se encontraron detalles para este evento.", image: nil))
                } else {
                    entryTypeDetails = tempEntryTypeDetails
                }

                loading = false
            } withCancel: { error in
                loading = false
                self.toast = .custom(.init(title: "", description: "Error al cargar detalles del evento: \(error.localizedDescription).", image: nil))
            }
        }
}
