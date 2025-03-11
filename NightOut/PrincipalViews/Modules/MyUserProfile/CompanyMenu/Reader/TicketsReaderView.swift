import SwiftUI
import AVFoundation
import FirebaseDatabase

struct TicketsReaderView: View {
    
    @State private var scannedQR: String? = nil
    @State private var showSuccess = false
    @State private var showError = false
    @State private var message: String = ""
    @State private var showTicketInfo = false
    
    @State private var ticketInfo: TicketQRReaderInfo?
    
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
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
            
            // 📌 Mensaje de estado
            if showSuccess || showError {
                Text(showSuccess ? "¡Acceso permitido!" : "Error en la entrada")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 140)
                    .transition(.opacity)
            }
            
            // 🔽 Switch y texto en la parte inferior
            VStack {
                Spacer()
                HStack {
                    Toggle(isOn: $showTicketInfo) {
                        Text("Mostrar info de la entrada")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.teal))
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            qrScanner.startScanning { result in
                checkTicketInDatabase(qrText: result)
            }
        }
        .sheet(isPresented: $showTicketInfo) {
            if let ticket = ticketInfo {
                TicketInfoBottomSheet(ticket: ticket, isPresented: $showTicketInfo)
            }
        }
        
    }
    
    private func checkTicketInDatabase(qrText: String) {
        guard let currentUserUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            message = "Usuario no autenticado"
            showErrorAnimation()
            return
        }
        
        let dbRef = Database.database().reference()
            .child("Company_Users")
            .child(currentUserUid)
            .child("TicketsVendidos")
        
        dbRef.getData { error, snapshot in
            guard error == nil, let snapshot = snapshot, snapshot.exists() else {
                message = "Error al consultar la base de datos"
                showErrorAnimation()
                return
            }
            
            var ticketFound = false
            let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            
            for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                if let storedQR = child.childSnapshot(forPath: "qrText").value as? String, storedQR == qrText {
                    ticketFound = true
                    
                    let validado = child.childSnapshot(forPath: "validado").value as? Bool ?? false
                    let nombre = child.childSnapshot(forPath: "nombre").value as? String ?? "Desconocido"
                    let tipoEntrada = child.childSnapshot(forPath: "tipo de entrada").value as? String ?? "N/A"
                    let correo = child.childSnapshot(forPath: "correo").value as? String ?? "N/A"
                    let precio = child.childSnapshot(forPath: "precio").value as? String ?? "N/A"
                    let fecha = child.childSnapshot(forPath: "fecha").value as? String ?? "N/A"
                    
                    if fecha != currentDate {
                        message = "Entrada no válida para hoy (\(fecha))"
                        showErrorAnimation()
                        return
                    }
                    
                    if validado {
                        message = "Entrada ya validada"
                        showErrorAnimation()
                    } else {
                        child.ref.child("validado").setValue(true)
                        message = "Acceso permitido"
                        showSuccessAnimation()
                        ticketInfo = TicketQRReaderInfo(
                            nombre: nombre,
                            tipoEntrada: tipoEntrada,
                            correo: correo,
                            precio: precio,
                            fecha: fecha
                        )
                        showTicketInfo = true
                    }
                    return
                }
            }
            
            if !ticketFound {
                message = "Entrada no válida"
                showErrorAnimation()
            }
        }
    }
    
    private func showSuccessAnimation() {
        showSuccess = true
        showError = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccess = false
            message = ""
        }
    }
    
    private func showErrorAnimation() {
        showSuccess = false
        showError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showError = false
            message = ""
        }
    }
}
