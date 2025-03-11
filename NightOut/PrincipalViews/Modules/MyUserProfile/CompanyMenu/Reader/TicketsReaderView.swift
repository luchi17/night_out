import SwiftUI
import AVFoundation
import FirebaseDatabase

struct TicketsReaderView: View {
    
    @State private var scannedQR: String? = nil
    @State private var showSuccess = false
    @State private var showError = false
    @State private var message: String = ""
    @State private var showTicketInfo = false
    
    @State private var shouldShowTicketInfo = false
    
    @State private var ticketInfo: TicketQRReaderInfo?
    
    @State private var lastScannedQR: String? = nil
    @State private var lastScanTime: TimeInterval = 0
    
    let onClose: () -> Void
    
    var qrScanner = QRScanner()
    
    var body: some View {
        ZStack {
            // 📷 Vista de la Cámara
            CameraPreview(session: qrScanner.session)
                .edgesIgnoringSafeArea(.all)
            
            // ✅ Icono de éxito
            if showSuccess {
                Image("tick_icon")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .transition(.opacity)
            }
            
            // ❌ Icono de error
            if showError {
                Image("cross_nb")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .transition(.opacity)
            }
            
            // 📌 Mensaje de estado
            Text(message)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 120)
                .transition(.opacity)
            
            // 🔽 Switch y texto en la parte inferior
            VStack {
                Spacer()
                HStack {
                    Toggle(isOn: $showTicketInfo) {
                        Text("Mostrar info de la entrada")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.green))
                }
            }
            .padding(.bottom, 16)
            .padding(.horizontal, 20)
        }
        .overlay(alignment: .topTrailing) {
            HStack {
                Spacer()
                
                Button(action: {
                    print("onclose")
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.trailing, 25)
        }
        
        .onAppear {
            // Solo ejecutamos checkTicketInDatabase si el QR ha cambiado
            
            qrScanner.startScanning { result in
                
                let currentTime = Date().timeIntervalSince1970
                
                if result != lastScannedQR || currentTime - lastScanTime > 3 {
                    lastScannedQR = result
                    lastScanTime = currentTime
                    
                    // 🔹 Reseteamos los mensajes antes de validar un nuevo QR
                    message = ""
                    showSuccess = false
                    showError = false
                    
                    checkTicketInDatabase(qrText: result)
                }
                
            }
        }
        .sheet(isPresented: $shouldShowTicketInfo) {
            if let ticket = ticketInfo {
                TicketInfoBottomSheet(ticket: ticket, isPresented: $showTicketInfo)
            }
        }
        
    }
    
    private func checkTicketInDatabase(qrText: String) {
        guard let currentUserUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            showError(message: "Usuario no autenticado")
            return
        }
        
        let dbRef = Database.database().reference()
            .child("Company_Users")
            .child("r8DtagpffQUyZVNhSoUGz1Qgwga2")
            .child("TicketsVendidos")
        
        dbRef.getData { error, snapshot in
            guard error == nil, let snapshot = snapshot, snapshot.exists() else {
                showError(message: "Error al consultar la base de datos")
                return
            }
            
            var ticketFound = false
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy"
         
            //GOOD CODE
//           let currentDate = dateFormatter.string(from: Date())
            
            var dateComponents = DateComponents()
            dateComponents.year = 2025
            dateComponents.month = 3
            dateComponents.day = 12
            
            let date = Calendar.current.date(from: dateComponents)
            
            let currentDate = dateFormatter.string(from: date!)
            
            for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                
                print(child.childSnapshot(forPath: "qrText").value as? String)
                
                if let storedQR = child.childSnapshot(forPath: "qrText").value as? String, storedQR == qrText {
                    ticketFound = true
                    
                    let validado = child.childSnapshot(forPath: "validado").value as? Bool ?? false
                    let nombre = child.childSnapshot(forPath: "nombre").value as? String ?? "Desconocido"
                    let tipoEntrada = child.childSnapshot(forPath: "tipo de entrada").value as? String ?? "N/A"
                    let correo = child.childSnapshot(forPath: "correo").value as? String ?? "N/A"
                    let precio = child.childSnapshot(forPath: "precio").value as? String ?? "N/A"
                    let fecha = child.childSnapshot(forPath: "fecha").value as? String ?? "N/A"
                    
                    if fecha != currentDate {
                        showError(message: "Entrada no válida para hoy (\(fecha))")
                        return
                    }
                    
                    if validado {
                        showError(message: "Entrada ya validada")
                    } else {
                        child.ref.child("validado").setValue(true)
                        showSuccess(message: "¡Acceso permitido!")
                        ticketInfo = TicketQRReaderInfo(
                            nombre: nombre,
                            tipoEntrada: tipoEntrada,
                            correo: correo,
                            precio: precio,
                            fecha: fecha
                        )
                        shouldShowTicketInfo = showTicketInfo
                    }
                    return
                }
            }
            
            if !ticketFound {
                showError(message: "Entrada no válida")
            }
        }
    }
    
    private func showSuccess(message: String) {
        showSuccess = true
        showError = false
        self.message = message
    }
    
    private func showError(message: String) {
        showSuccess = false
        showError = true
        self.message = message
    }
}
