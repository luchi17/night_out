import SwiftUI
import WebKit
import FirebaseDatabase

struct DatosEventoView: View {
    @State private var htmlContent: String = "<h2>Cargando...</h2>"
    @State private var isLoading: Bool = true
    @State private var toast: ToastType?
    
    let onClose: VoidClosure
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            }
            WebView(htmlContent: $htmlContent)
                .opacity(isLoading ? 0 : 1)
                .padding(.top, 30)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.black)
            }
            .padding(.top, 10)
            .padding(.trailing, 15)
        }
        .background(
            Color.whiteHTML.ignoresSafeArea()
        )
        .showToast(
            error: (
                type: toast,
                showCloseButton: false,
                onDismiss: {
                    toast = nil
                }
            ),
            isIdle: false
        )
        .onAppear {
            obtenerFechaEventoMasCercano { fechaEvento in
                if let fecha = fechaEvento {
                    obtenerDatosDesdeFirebase(fechaEvento: fecha) { asistentes in
                        if !asistentes.isEmpty {
                            htmlContent = generarHTML(asistentes: asistentes)
                        } else {
                            htmlContent = "<h2>No hay asistentes en este evento</h2>"
                        }
                        isLoading = false
                    }
                } else {
                    htmlContent = "<h2>No hay eventos próximos</h2>"
                    isLoading = false
                }
            }
        }
    }
    
    func obtenerFechaEventoMasCercano(completion: @escaping (String?) -> Void) {
        guard let currentUserUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            self.toast = .custom(.init(title: "", description: "Usuario no autenticado.", image: nil))
            completion(nil)
            return
        }
        
        let databaseReference =  FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: currentUserUid)
            .child("Entradas")
        
        databaseReference.observeSingleEvent(of: .value) { snapshot in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy"
            dateFormatter.locale = Locale.current
            
            let currentDate = dateFormatter.date(from: dateFormatter.string(from: Date()))!
            
            var fechaMasCercana: String?
            var diferenciaMinima: TimeInterval = .greatestFiniteMagnitude
            
            for child in snapshot.children {
                guard let fechaSnapshot = child as? DataSnapshot else { continue }
                let fechaTexto = fechaSnapshot.key
                
                if let fechaEvento = dateFormatter.date(from: fechaTexto) {
                    let diferencia = abs(fechaEvento.timeIntervalSince(currentDate))
                    
                    if diferencia < diferenciaMinima {
                        diferenciaMinima = diferencia
                        fechaMasCercana = fechaTexto
                    }
                } else {
                    self.toast = .custom(.init(title: "", description: "Error procesando fecha: formato inválido.", image: nil))
                }
            }
            
            if fechaMasCercana == nil {
                self.toast = .custom(.init(title: "", description: "No se encontró un evento cercano", image: nil))
            }
            completion(fechaMasCercana)
        } withCancel: { error in
            self.toast = .custom(.init(title: "", description: "Error obteniendo fechas: \(error.localizedDescription).", image: nil))
            completion(nil)
        }
    }
    
    
    func obtenerDatosDesdeFirebase(fechaEvento: String, completion: @escaping ([[String: String]]) -> Void) {
        guard let currentUserUid = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            self.toast = .custom(.init(title: "", description: "Usuario no autenticado.", image: nil))
            completion([])
            return
        }
        
        let databaseReference =  FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: currentUserUid)
            .child("Entradas")
            .child(fechaEvento)
        
        databaseReference.observeSingleEvent(of: .value) { snapshot in
            var asistentes: [[String: String]] = []
            
            for eventoSnapshot in snapshot.children {
                guard let eventoData = eventoSnapshot as? DataSnapshot else { continue }
                let nombreEvento = eventoData.key
                
                let ticketsVendidosSnapshot = eventoData.childSnapshot(forPath: "TicketsVendidos")
                if !ticketsVendidosSnapshot.exists() { continue }
                
                for ticketSnapshot in ticketsVendidosSnapshot.children {
                    guard let ticketData = ticketSnapshot as? DataSnapshot else { continue }
                    
                    // 🔹 Ignorar la entrada "lastTicketNumber"
                    if ticketData.key == "lastTicketNumber" { continue }
                    
                    // 🔹 Obtener datos asegurando que sean Strings
                    let nombre = ticketData.childSnapshot(forPath: "nombre").value as? String ?? "Sin nombre"
                    let precio = ticketData.childSnapshot(forPath: "precio").value as? String ?? "0"
                    let validado = ticketData.childSnapshot(forPath: "validado").value as? Bool ?? false
                    
                    // 📌 Agregar a la lista
                    asistentes.append([
                        "nombre": nombre,
                        "evento": nombreEvento,
                        "precio": precio,
                        "validado": validado ? "true" : "false"
                    ])
                }
            }
            
            if asistentes.isEmpty {
                self.toast = .custom(.init(title: "", description: "No se encontraron asistentes para esta fecha.", image: nil))
            } else {
                //                self.toast = .success(.init(title: "", description: "Se encontraron \(asistentes.count) asistentes", image: nil))
            }
            
            completion(asistentes)
        } withCancel: { error in
            self.toast = .custom(.init(title: "", description: "Error al obtener asistentes: \(error.localizedDescription)", image: nil))
            completion([])
        }
    }
    
    // MARK: - Generar HTML
    func generarHTML(asistentes: [[String: String]]) -> String {
        let eventosAgrupados = Dictionary(grouping: asistentes, by: { $0["evento"] ?? "Evento Desconocido" })
        
        // 📊 Cálculo de estadísticas
        let totalEntradas = asistentes.count
        let totalValidadas = asistentes.filter { $0["validado"] == "true" }.count
        let porcentajeValidado = totalEntradas > 0 ? (totalValidadas * 100) / totalEntradas : 0
        
        let recuentoPrecios = Dictionary(grouping: asistentes, by: { $0["precio"] ?? "Desconocido" })
            .mapValues { $0.count }
        
        // 💰 Cálculo de ingresos
        let totalRecaudado = asistentes.reduce(0.0) { $0 + (Double($1["precio"] ?? "0") ?? 0) }
        let totalRecaudadoValidado = asistentes
            .filter { $0["validado"] == "true" }
            .reduce(0.0) { $0 + (Double($1["precio"] ?? "0") ?? 0) }
        let totalRecaudadoNoValidado = totalRecaudado - totalRecaudadoValidado
        
        // 📉 Beneficio después de IVA (21%) sobre el TOTAL RECAUDADO
        let beneficioDespuesIVA = totalRecaudado / 1.21
        
        let fotoURL = convertirImagenEnBase64(nombreImagen: "foto_naturaleza_web")!
        let logoURL = convertirImagenEnBase64(nombreImagen: "logo_amarillo")!
        
        return """
        <html>
        <head>
            <title>Gestión de Eventos</title>
            <style>
                body { font-family: Arial, sans-serif; text-align: center; background-color: #f8f9fa; margin: 0; padding: 0; }
                .container { width: 80%; margin: 20px auto; padding: 20px; background: white; border-radius: 10px; box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.1); }
                h2 { color: #333; }
                table { width: 100%; margin-top: 20px; border-collapse: collapse; }
                th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
                th { background-color: #007bff; color: white; }
                .validado { text-decoration: underline; font-weight: bold; color: green; }
                
                /* Estilos para la cabecera */
                .header {
                    position: relative;
                    width: 100%;
                    height: 200 px;
                }
        
                .header img.cabecera {
                    width: 100%;
                    height: 250;
                    display: block;
                    object-fit: cover;
                }
        
                .header img.logo {
                    position: absolute;
                    top: 10px;
                    right: 10px;
                    height: 60px;
                    width: auto;
                }
        
                /* Pestañas */
                .tab-container {
                    display: flex;
                    justify-content: center;
                    margin-top: 20px;
                }
                .tab {
                    padding: 10px 20px;
                    cursor: pointer;
                    background-color: #ddd;
                    border: 1px solid #bbb;
                    border-bottom: none;
                    margin-right: 5px;
                    border-radius: 10px 10px 0 0;
                }
                .tab.active {
                    background-color: #007bff;
                    color: white;
                }
                .tab-content {
                    display: none;
                    padding: 20px;
                }
                .tab-content.active {
                    display: block;
                }
            </style>
            <script>
                function showTab(tabId) {
                    document.querySelectorAll('.tab-content').forEach(tab => tab.classList.remove('active'));
                    document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
                    document.getElementById(tabId).classList.add('active');
                    document.querySelector('[data-tab="'+tabId+'"]').classList.add('active');
                }
            </script>
        </head>
        <body>
            <div class="container">
                <!-- Cabecera con imagen -->
                <div class="header">
                    <img src="\(fotoURL)" class="cabecera" alt="Cabecera">
                    <img src="\(logoURL)" class="logo" alt="Logo">
                </div>
                <!-- Pestañas -->
                <div class="tab-container">
                    <div class="tab active" data-tab="asistencia" onclick="showTab('asistencia')">Asistencia</div>
                    <div class="tab" data-tab="estadisticas" onclick="showTab('estadisticas')">Estadísticas</div>
                </div>
        
                <!-- Contenido de Asistencia -->
                <div id="asistencia" class="tab-content active">
                    <h2>Lista de Asistentes</h2>
                    \(eventosAgrupados.map { evento, asistentes in
                        """
                        <h3>\(evento)</h3>
                        <table>
                            <tr>
                                <th>Nombre</th>
                                <th>Precio (€)</th>
                                <th>Estado</th>
                            </tr>
                            \(asistentes.map { asistente in
                                let nombre = asistente["nombre"] ?? "Desconocido"
                                let precio = asistente["precio"] ?? "0.0"
                                let validado = asistente["validado"] == "true"
                                return """
                                <tr>
                                    <td>\(validado ? "<span class='validado'>\(nombre)</span>" : nombre)</td>
                                    <td>\(precio)</td>
                                    <td>\(validado ? "✅ Validado" : "❌ No validado")</td>
                                </tr>
                                """
                            }.joined())
                        </table>
                        """
                    }.joined())
                </div>
        
                <!-- Contenido de Estadísticas -->
                <div id="estadisticas" class="tab-content">
                    <h2>📊 Estadísticas Generales</h2>
                    <p><strong>Total de entradas:</strong> \(totalEntradas)</p>
                    <p><strong>Entradas validadas:</strong> \(totalValidadas) (\(porcentajeValidado)%)</p>
                    
                    <p><strong>💰 Dinero total recaudado:</strong> \(String(format: "%.2f", totalRecaudado)) €</p>
                    <p><strong>✅ Dinero de entradas validadas:</strong> \(String(format: "%.2f", totalRecaudadoValidado)) €</p>
                    <p><strong>❌ Dinero de entradas no validadas:</strong> \(String(format: "%.2f", totalRecaudadoNoValidado)) €</p>
                    <p><strong>📉 Beneficio después de IVA (21%):</strong> \(String(format: "%.2f", beneficioDespuesIVA)) €</p>
        
                    <h3>📈 Distribución de Precios</h3>
                    <table>
                        <tr>
                            <th>Precio (€)</th>
                            <th>Cantidad</th>
                        </tr>
                        \(recuentoPrecios.map { precio, cantidad in
                            "<tr><td>\(precio)</td><td>\(cantidad)</td></tr>"
                        }.joined())
                    </table>
                </div>
        
            </div>
        </body>
        </html>
        """
    }
    
    func convertirImagenEnBase64(nombreImagen: String, tipo: String = "png") -> String? {
        if let imagen = UIImage(named: nombreImagen),
           let datos = imagen.pngData() {
            let base64String = datos.base64EncodedString()
            return "data:image/\(tipo);base64,\(base64String)"
        }
        return nil
    }
}

struct WebView: UIViewRepresentable {
    @Binding var htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false // Hace que el fondo sea visible
        webView.backgroundColor = UIColor(named: "whiteHTML") // Fondo blanco en la carga
        webView.scrollView.backgroundColor = UIColor(named: "whiteHTML")
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
