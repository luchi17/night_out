import SwiftUI
import UIKit
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL // new variable to get the URL of the document
    
    func makeUIView(context: UIViewRepresentableContext<PDFKitView>) -> PDFView {
        // Creating a new PDFVIew and adding a document to it
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<PDFKitView>) {
        // we will leave this empty as we don't need to update the PDF
    }
}

class PDFDownloader {
    
    static func descargarYMostrarPDF(desde url: URL?, name: String, numeroTicket: String) {
        guard let url = url else {
            print("URL inválida")
            return
        }
        
        // Crear una sesión de descarga
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                print("Error al descargar el PDF: \(error?.localizedDescription ?? "Desconocido")")
                return
            }
            
            // Obtener el directorio de documentos
            let documentosURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("EventTickets")
            
            let destinoURL = documentosURL.appendingPathComponent("ticket_\(name)_\(numeroTicket).pdf")

            // Mover el archivo descargado a Documentos
            do {
                if FileManager.default.fileExists(atPath: destinoURL.path) {
                    try FileManager.default.removeItem(at: destinoURL)
                }
                try FileManager.default.moveItem(at: localURL, to: destinoURL)
                
                // Mostrar el PDF al usuario en el Share Sheet
                DispatchQueue.main.async {
                    let activityVC = UIActivityViewController(activityItems: [destinoURL], applicationActivities: nil)
                    // Mostrar el controlador de actividad
                    if let topController = UIApplication.shared.keyWindow?.rootViewController {
                        topController.present(activityVC, animated: true, completion: nil)
                    }
                }
                
            } catch {
                print("Error al guardar el archivo: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
