import SwiftUI
import FirebaseDatabase

struct HistoryBottomSheet: View {
    
    var ticketNumberToShow: String
    
    @Binding var isPresented: Bool
    
    @State private var nombreEvento: String = ""
    @State private var fechaEvento: String = ""
    @State private var referenciaCompra: String = ""
    @State private var precioEntrada: String = ""
    
    @State private var qrImage: IdentifiableImage?
    @State private var selectedQRImage: IdentifiableImage?
    
    @State private var loading: Bool = false
    @State private var toast: ToastType?
    
    var body: some View {
        
        ScrollView(.vertical) {
            
            if !loading {
                content
            }
        }
        .scrollIndicators(.hidden)
        .background(
            Color.white.ignoresSafeArea()
        )
        .fullScreenCover(item: $selectedQRImage) { imageName in
            FullScreenImageView(imageName: imageName, onClose: {
                selectedQRImage = nil
            })
        }
        .showToast(
            error: (
                type: toast,
                showCloseButton: false,
                onDismiss: {
                    toast = nil
                }
            ),
            isIdle: loading,
            extraPadding: .none
        )
        .onAppear {
            obtenerDatosTicket()
        }
    }
    
    var content: some View {
        VStack(alignment: .center, spacing: 12) {
            
            HStack {
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image("borrar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color.blackColor)
                }
            }
            
            Text(nombreEvento)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Text(fechaEvento)
                .font(.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            // Código QR
            if let qrImage = qrImage {
                Image(uiImage: qrImage.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.bottom, 10)
                    .onTapGesture {
                        selectedQRImage = qrImage
                    }
            } else {
                Text("QR no encontrado")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .bold()
            }
            // Línea Separadora
            Divider()
                .background(Color.gray.opacity(0.6))
                .padding(.vertical, 10)
            
            // Sección: Detalles de mi compra
            VStack(alignment: .leading, spacing: 6) {
                Text("Detalles de mi compra")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text("Referencia de compra: \(referenciaCompra)")
                    .font(.subheadline)
                    .foregroundColor(.black)
                
                Text("Precio: \(precioEntrada)")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            // Condiciones de compra
            Text("Los términos y condiciones del recinto y/o el promotor del evento también pueden aplicar.")
                .font(.footnote)
                .foregroundColor(.black)
                .padding(.bottom, 10)
        }
        .padding(20)
    }
    
    
    private func obtenerDatosTicket() {
        
        self.loading = true
        
        guard let currentUserUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            print("Usuario no autenticado")
            isPresented = false
            return
        }
        
        let dbRef = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: currentUserUid)
        
        dbRef.child("MisEntradas").child(ticketNumberToShow)
            .getData { error, snapshot in
                
                guard error == nil, let snapshot = snapshot, snapshot.exists(),
                      let ticketData = snapshot.value as? [String: Any] else {
                    print("No se pudo obtener la entrada")
                    self.isPresented = false
                    self.loading = false
                    return
                }
                
                DispatchQueue.main.async {
                    self.nombreEvento = ticketData["evento"] as? String ?? "Evento no disponible"
                    self.fechaEvento = ticketData["fecha"] as? String ?? "Fecha no disponible"
                    self.referenciaCompra = ticketData["numeroTicket"] as? String ?? "No disponible"
                    self.precioEntrada = ticketData["precio"] as? String ?? "No disponible"
                    
                    if let base64String = ticketData["qrCodeBase64"] as? String, let qrImage = self.base64ToUIImage(base64String) {
                        self.qrImage = IdentifiableImage(image: qrImage)
                    }
                    
                    self.loading = false
                }
            }
    }
    
    private func base64ToUIImage(_ base64String: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    private func mostrarQrCompleto() {
        
        // Aquí podrías abrir otra vista en pantalla completa con el QR
    }
    
    
}

//
//struct BigQRSheet: View {
//    
//    var body: some View {
//        
//    }
//}
