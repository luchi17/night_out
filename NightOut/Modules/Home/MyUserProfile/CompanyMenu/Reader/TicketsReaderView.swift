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
            
            VStack {
                // ✅ Icono de éxito
                if showSuccess {
                    Image("tick_icon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .transition(.opacity)
                        .foregroundStyle(.green)
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
                    .padding(.top, 15)
                    .transition(.opacity)
            }
            .padding(.top, 100)
            
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
                        .frame(width: 25, height: 25)
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.top, 30)
            .padding(.trailing, 25)
        }
        .onAppear {
            // Solo ejecutamos checkTicketInDatabase si el QR ha cambiado
            qrScanner.startScanning { result in
                
                guard !shouldShowTicketInfo, !showError, !showSuccess else { return }
                
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
        .sheet(isPresented: $shouldShowTicketInfo, onDismiss: {
            ticketInfo = nil
            shouldShowTicketInfo = false
        }) {
            if let ticket = ticketInfo {
                TicketInfoBottomSheet(
                    ticket: ticket,
                    isPresented: $shouldShowTicketInfo
                )
                .presentationDetents([.fraction(0.35), .medium])
            }
        }
    }
    
    private func checkTicketInDatabase(qrText: String) {
        guard let currentUserUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            showError(message: "Usuario no autenticado")
            return
        }
        //Discomment FOR testing
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 7
        dateComponents.day = 20
        
        let date = Calendar.current.date(from: dateComponents)
        let currentDate = dateFormatter.string(from: date!)
        
//        let currentDate = dateFormatter.string(from: Date())
        
        let dbRef = Database.database().reference()
            .child("Company_Users")
            .child(currentUserUid) // "r8DtagpffQUyZVNhSoUGz1Qgwga2" for testing
            .child("Entradas")
            .child(currentDate)
        
        dbRef.getData { error, snapshot in
            guard error == nil, let snapshot = snapshot else {
                showError(message: "Error al consultar la base de datos")
                return
            }
            
            if !snapshot.exists() {
                showError(message: "No hay eventos hoy")
                return
            }
            
            for eventoSnapshot in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                
                let ticketsVendidosSnapshot = eventoSnapshot.childSnapshot(forPath: "TicketsVendidos")
                guard ticketsVendidosSnapshot.exists() else { continue }
                
                for ticketSnapshot in ticketsVendidosSnapshot.children.allObjects as? [DataSnapshot] ?? [] {
                    
                    if let storedQrText = ticketSnapshot.childSnapshot(forPath: "qrText").value as? String,
                       
                        storedQrText.trimmingCharacters(in: .whitespacesAndNewlines) == qrText.trimmingCharacters(in: .whitespacesAndNewlines) {
                        
                        let validado = ticketSnapshot.childSnapshot(forPath: "validado").value as? Bool ?? false
                        
                        let nombre = ticketSnapshot.childSnapshot(forPath: "nombre").value as? String ?? "Desconocido"
                        let tipoEntrada = ticketSnapshot.childSnapshot(forPath: "tipo de entrada").value as? String ?? "N/A"
                        let correo = ticketSnapshot.childSnapshot(forPath: "correo").value as? String ?? "N/A"
                        let precio = ticketSnapshot.childSnapshot(forPath: "precio").value as? String ?? "N/A"
                        let fecha = ticketSnapshot.childSnapshot(forPath: "fecha").value as? String ?? "N/A"
                        
                        ticketInfo = TicketQRReaderInfo(
                            nombre: nombre,
                            tipoEntrada: tipoEntrada,
                            correo: correo,
                            precio: precio,
                            fecha: fecha
                        )
                       
                        if validado {
                            showError(message: "Entrada ya validada")
                            
                        } else {
                            ticketSnapshot.ref.child("validado").setValue(true)
                            showSuccess(message: "Acceso permitido")
                        }
                        
                        return
                    }
                }
            }
            
            showError(message: "Entrada no válida")
        }
    }
    
    private func showSuccess(message: String) {
        showSuccess = true
        showError = false
        self.message = message
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showSuccess = false
            self.showError = false
            self.message = ""
            self.shouldShowTicketInfo = showTicketInfo && ticketInfo != nil
        }
    }
    
    private func showError(message: String) {
        showSuccess = false
        showError = true
        self.message = message
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showSuccess = false
            self.showError = false
            self.message = ""
        }
    }
}
