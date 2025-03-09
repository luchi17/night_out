import SwiftUI
import MessageUI

struct MailComposerView: UIViewControllerRepresentable {
    var destinatario: String
    var pdfFileURL: URL
    var onResult: (MFMailComposeResult) -> Void

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposerView

        init(parent: MailComposerView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.onResult(result)
            controller.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.setToRecipients([destinatario])
        mailComposer.setSubject("Tu entrada para el evento NightOut")
        mailComposer.setMessageBody("""
        ¡Gracias por tu compra!

        Adjuntamos tu entrada en formato PDF. 
        Por favor, no olvides llevarla al evento para su validación.

        Saludos,
        Equipo de NightOut Spain
        """, isHTML: false)

        // Adjuntar el PDF
        if let pdfData = try? Data(contentsOf: pdfFileURL) {
            mailComposer.addAttachmentData(pdfData, mimeType: "application/pdf", fileName: "entrada.pdf")
        }
        
        mailComposer.mailComposeDelegate = context.coordinator
        return mailComposer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}
