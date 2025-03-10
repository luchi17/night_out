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


class PDFDownloader: NSObject {
    static let shared = PDFDownloader()
    private var documentInteractionController: UIDocumentInteractionController?

    func descargarYMostrarPDF(desde url: URL?, name: String, numeroTicket: String) {
        guard let url = url else {
            print("URL inválida")
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
            guard let localURL = localURL, error == nil else {
                print("Error al descargar el PDF: \(error?.localizedDescription ?? "Desconocido")")
                return
            }
            
            // Obtener el directorio de documentos
            let documentosURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("EventTickets")
            let destinoURL = documentosURL.appendingPathComponent("ticket_\(name)_\(numeroTicket).pdf")
            
            do {
                if FileManager.default.fileExists(atPath: destinoURL.path) {
                    try FileManager.default.removeItem(at: destinoURL)
                }
                try FileManager.default.moveItem(at: localURL, to: destinoURL)
                
                // Abrir el PDF en un visor dentro de la app
                
                DispatchQueue.main.async {
                    if let topController = UIApplication.shared.keyWindow?.rootViewController {
                        self.abrirPDF(en: destinoURL, desde: topController)
                    }
                }
                
            } catch {
                print("Error al guardar el archivo: \(error.localizedDescription)")
            }
        }
        task.resume()
    }

    private func abrirPDF(en url: URL, desde viewController: UIViewController) {
        documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController?.delegate = self
        documentInteractionController?.presentPreview(animated: true)
    }
}

// Extensión para mostrar el visor
extension PDFDownloader: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
    }
}
