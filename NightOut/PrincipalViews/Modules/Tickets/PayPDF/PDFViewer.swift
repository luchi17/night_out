import SwiftUI
import UIKit
import PDFKit

//// Representable para abrir PDF
//struct PDFViewer: UIViewControllerRepresentable {
//    
//    var pdfURL: URL
//
//    func makeUIViewController(context: Context) -> UIDocumentInteractionController {
//        let controller = UIDocumentInteractionController(url: pdfURL)
//        controller.delegate = context.coordinator
//        return controller
//    }
//
//    func updateUIViewController(_ uiViewController: UIDocumentInteractionController, context: Context) {}
//
//    // Coordinator para manejar los eventos de presentación
//    class Coordinator: NSObject, UIDocumentInteractionControllerDelegate {
//        
//        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
//            return UIApplication.shared.windows.first!.rootViewController!
//        }
//
//        func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
//            print("Preview ended")
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        return Coordinator()
//    }
//}


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
