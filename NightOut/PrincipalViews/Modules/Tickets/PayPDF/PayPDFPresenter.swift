import Combine
import SwiftUI
import Firebase
import PDFKit
import CoreImage
import UIKit
import MessageUI

struct TicketPDFModel: Hashable {
    let name: String
    let pdf: URL?
}

struct PDFModel {
    let nameEvent: String
    let date: String
    let companyuid: String
    let quantity: Int
    let price: Double
    let type: String
    let personDataList: [PersonTicketData]
    
    init(nameEvent: String, date: String, companyuid: String, quantity: Int, personDataList: [PersonTicketData], price: Double, type: String) {
        self.nameEvent = nameEvent
        self.date = date
        self.companyuid = companyuid
        self.quantity = quantity
        self.personDataList = personDataList
        self.price = price
        self.type = type
    }
}

class PayPDFViewModel: ObservableObject {
    
    @Published var loading: Bool = false
    @Published var toast: ToastType?
    
    @Published var model: PDFModel
    @Published var isShowingMailComposer: Bool = false
    @Published var emailPdf: String = ""
    @Published var pdfString: URL?
    @Published var pdfToShow: URL?
    
    @Published var ticketsList: [TicketPDFModel] = []
    
    init(model: PDFModel) {
        self.model = model
    }
}

protocol PayPDFPresenter {
    var viewModel: PayPDFViewModel { get }
    func transform(input: PayPDFPresenterImpl.Input)
}

final class PayPDFPresenterImpl: PayPDFPresenter {
    var viewModel: PayPDFViewModel
    
    struct Input {
        let viewIsLoaded: AnyPublisher<Void, Never>
        let goBack: AnyPublisher<Void, Never>
        let openPDf: AnyPublisher<TicketPDFModel, Never>
        let downloadPdf: AnyPublisher<TicketPDFModel, Never>
    }
    
    struct UseCases {
        
    }
    
    struct Actions {
    }
    
    // MARK: - Stored Properties
    private let actions: Actions
    private let useCases: UseCases
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: - Lifecycle
    init(actions: Actions, useCases: UseCases, model: PDFModel) {
        
        self.viewModel = PayPDFViewModel(model: model)
        self.actions = actions
        self.useCases = useCases
        
    }
    
    func transform(input: Input) {
        
        input
            .viewIsLoaded
            .withUnretained(self)
            .sink { presenter, _ in
                
                presenter.viewModel.loading = true
                
                for user in presenter.viewModel.model.personDataList {
                    print("generando PDF para \(user.name)")
                    
                    presenter.generatePdf(person: user) { pdfUrl in
                        presenter.viewModel.loading = false
                        
                        let ticket = TicketPDFModel(name: user.name, pdf: pdfUrl)
                        presenter.viewModel.ticketsList.append(ticket)
                        
                        //MANDAR EMAIL
                        
                        //self.viewModel.emailPdf = user.email
                        //self.viewModel.pdfString = pdfUrl
                    }
                }
            }
            .store(in: &cancellables)
        
        input
            .downloadPdf
            .withUnretained(self)
            .sink { presenter, _ in
                
            }
            .store(in: &cancellables)
        
        
    }
    
    func generateQrCode(text: String) -> UIImage? {
        // Crear un filtro de tipo QR Code usando CoreImage
        let data = text.data(using: .utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel") // El nivel de corrección de error (opcional)
        
        // Obtener la imagen resultante del filtro
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        // Para mejorar la resolución, podemos convertir la imagen CIImage a UIImage con un tamaño mayor
        let context = CIContext()
        let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        let qrCodeImage = UIImage(cgImage: cgImage!)
        
        return qrCodeImage
    }
    
    
    //    func generateQrCode(text: String) -> UIImage? {
    //        let data = text.data(using: .utf8)
    //
    //        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
    //            return nil
    //        }
    //        filter.setValue(data, forKey: "inputMessage")
    //        filter.setValue("Q", forKey: "inputCorrectionLevel")
    //
    //        guard let outputImage = filter.outputImage else { return nil }
    //
    //        let scaleX = CGFloat(200) / outputImage.extent.size.width
    //        let scaleY = CGFloat(200) / outputImage.extent.size.height
    //        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    //
    //        return UIImage(ciImage: transformedImage)
    //    }
    
    func bitmapToByteArray(bitmap: UIImage) -> Data? {
        guard let imageData = bitmap.pngData() else { return nil }
        return imageData
    }
    
    func generatePdf(person: PersonTicketData, callback: @escaping (URL?) -> Void) {
        
        let pdfFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("EventTickets")
        
        if !FileManager.default.fileExists(atPath: pdfFolder.path) {
            do {
                try FileManager.default.createDirectory(at: pdfFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                callback(nil)
                return
            }
        }
        
        let databaseReference =
        FirebaseServiceImpl.shared
            .getCompanyInDatabaseFrom(uid: viewModel.model.companyuid)
            .child("Entradas/\(viewModel.model.date)/\(viewModel.model.nameEvent)/TicketsVendidos")
        
        let lastTicketNumberRef = databaseReference.child("lastTicketNumber")
        
        lastTicketNumberRef.getData { (error, snapshot) in
            guard error == nil else {
                print("Error al obtener lastTicketNumber: \(error!.localizedDescription)")
                return
            }
            
            let lastTicketNumber = snapshot?.value as? Int ?? 0
            let newTicketNumber = lastTicketNumber + 1
            let numeroTicket = "TICKET-\(newTicketNumber)"
            
            // Update Firebase with the new ticket number
            //            lastTicketNumberRef.setValue(newTicketNumber)
            
            // Generate the QR Code
            guard let qrCodeBitmap = self.generateQrCode(text: numeroTicket) else {
                print("No se pudo crear el qrCodeBitmap".uppercased())
                return
            }
            
            let qrCodeBase64 = self.encodeToBase64(bitmap: qrCodeBitmap)
            
            let ticketData: [String: Any] = [
                "nombre": person.name,
                "correo": person.email,
                "evento": self.viewModel.model.nameEvent,
                "tipo de entrada": self.viewModel.model.type,
                "precio": self.viewModel.model.price,
                "fecha": self.viewModel.model.date,
                "discoteca": self.viewModel.model.companyuid,
                "qrText": numeroTicket,
                "numeroTicket": numeroTicket,
                "qrCodeBase64": qrCodeBase64
            ]
            
            //            let userTicketRef = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userUID).child("MisEntradas").child(numeroTicket)
            //            userTicketRef.setValue(ticketData)
            //
            //            // Guardar en Firebase en el nodo de la empresa (TicketsVendidos)
            //            databaseReference.child(numeroTicket).setValue(ticketData)
            
            
            let companyUsersRef = FirebaseServiceImpl.shared
                .getCompanyInDatabaseFrom(uid: self.viewModel.model.companyuid)
                .child("username")
            
            companyUsersRef.getData { (error, snapshot) in
                guard error == nil else {
                    print("Error al obtener el username: \(error!.localizedDescription)")
                    return
                }
                
                let companyUsername = snapshot?.value as? String ?? "Nombre no disponible"
                
                self.createPDF(
                    numeroTicket: numeroTicket,
                    person: person,
                    companyUsername: companyUsername,
                    callback: callback
                )
                
            }
        }
    }
    
    func createPDF(numeroTicket: String, person: PersonTicketData, companyUsername: String, callback: @escaping (URL?) -> Void) {
        // Crear el archivo PDF
        
        let pdfFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("EventTickets")
        
        if !FileManager.default.fileExists(atPath: pdfFolder.path) {
            do {
                try FileManager.default.createDirectory(at: pdfFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return
            }
        }
        
        let pdfFilename = pdfFolder.appendingPathComponent("ticket_\(person.name)_\(numeroTicket).pdf")
        
        // Crear el PDF context
        UIGraphicsBeginPDFContextToFile(pdfFilename.path, .zero, nil)
        
        // Comienza una nueva página
        UIGraphicsBeginPDFPage()
        
        // Obtén el tamaño de la página del PDF
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let pageSize = context.boundingBoxOfClipPath.size
        
        // Dibuja la imagen de fondo
        guard let backgroundImage = UIImage(named: "pdf_view") else {
            print("no backgroundImage")
            return
        }
        
        // Calcular las dimensiones escaladas de la imagen manteniendo la proporción
        let imageSize = backgroundImage.size
        let imageAspect = imageSize.width / imageSize.height
        var scaledSize = CGSize(width: pageSize.width, height: pageSize.width / imageAspect)
        
        // Si la altura escalada es mayor que la altura de la página, ajustamos la altura
        if scaledSize.height > pageSize.height {
            scaledSize = CGSize(width: pageSize.height * imageAspect, height: pageSize.height)
        }
        
        // Calcular la posición para centrar la imagen en la página
        let x = (pageSize.width - scaledSize.width) / 2
        let y = (pageSize.height - scaledSize.height) / 2
        
        
        // Dibujar la imagen escalada en el contexto
        backgroundImage.draw(in: CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height))
        
        let boldFont = UIFont.boldSystemFont(ofSize: 12)
        let normalFont = UIFont.systemFont(ofSize: 12)
        let footerFont = UIFont.italicSystemFont(ofSize: 10)
        
        func addText(label: String, at point: CGPoint, font: UIFont) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            let attributedText = NSAttributedString(string: label, attributes: attributes)
            attributedText.draw(at: point)
        }
        
        let headerText = "EVENTO: \(self.viewModel.model.nameEvent)   DISCOTECA: \(companyUsername)"
        let titleYPosition: CGFloat = backgroundImage.size.height - 80
        
        //        let text = "Tu texto sobre la imagen"
        //            text.draw(at: CGPoint(x: 100, y: 100), withAttributes: textAttributes)
        addText(label: headerText, at: CGPoint(x: 50, y: titleYPosition), font: boldFont)
        
        // Finalizar el contexto del PDF
        UIGraphicsEndPDFContext()
        
        print("PDF guardado en: \(pdfFilename.path)")
        callback(pdfFilename)
    }
    
    
    
    
    func encodeToBase64(bitmap: UIImage) -> String {
        guard let imageData = bitmap.pngData() else { return "" }
        return imageData.base64EncodedString()
    }
    
    func drawTextInPDF(context: CGContext, text: String, atPoint point: CGPoint) {
        let font = UIFont.boldSystemFont(ofSize: 18) // Puedes usar cualquier font aquí
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: point)
    }
    
    func drawImage(in context: CGContext, image: UIImage, at point: CGPoint) {
        guard let cgImage = image.cgImage else { return }
        
        // Establece un rectángulo para la imagen usando su posición y tamaño
        let rect = CGRect(origin: point, size: image.size)
        
        // Dibuja la imagen en el contexto
        context.draw(cgImage, in: rect)
    }
    
    // Compartir el archivo (con la app "Archivos")
    func sharePDF() {
        let pdfFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfFilename = pdfFolder.appendingPathComponent("EventTickets/ticket_Mari_TICKET-18.pdf")
        
        // Crea un UIActivityViewController para compartir el archivo
        let activityViewController = UIActivityViewController(activityItems: [pdfFilename], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact]
        
        // Mostrar el controlador de actividad
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(activityViewController, animated: true, completion: nil)
        }
    }
}

//var yPosition: CGFloat = backgroundImage.size.height - 180
//
//addText(label: "Nombre: \(person.name)", at: CGPoint(x: 50, y: yPosition), font: boldFont)
//yPosition -= 30
//addText(label: "Correo: \(person.email)", at: CGPoint(x: 50, y: yPosition), font: normalFont)
//yPosition -= 30
//addText(label: "Número de Ticket: \(numeroTicket)", at: CGPoint(x: 50, y: yPosition), font: normalFont)
//yPosition -= 30
//addText(label: "Fecha: \(self.viewModel.model.date)", at: CGPoint(x: 50, y: yPosition), font: normalFont)
//yPosition -= 30
//addText(label: "Precio: \(self.viewModel.model.price) euros", at: CGPoint(x: 50, y: yPosition), font: normalFont)
//yPosition -= 30
//addText(label: "Evento: \(self.viewModel.model.nameEvent) euros", at: CGPoint(x: 50, y: yPosition), font: normalFont)
//yPosition -= 30
//addText(label: "Tipo de entrada: \(self.viewModel.model.type)", at: CGPoint(x: 50, y: yPosition), font: normalFont)
//yPosition -= 30
//
//// Agregar texto en el pie de página
//let footerText = "Condiciones del Ticket: Este ticket es personal e intransferible. Modificaciones no permitidas."
//addText(label: footerText, at: CGPoint(x: backgroundImage.size.width / 2, y: 30), font: footerFont)
//
//
//// Agregar el código QR
//let qrCodeXPosition = (backgroundImage.size.width - qrCodeBitmap.size.width) / 2
//let qrCodeYPosition = (backgroundImage.size.height - qrCodeBitmap.size.height) / 2
//
//self.drawImage(in: pdfContext, image: qrCodeBitmap, at: CGPoint(x: qrCodeXPosition, y: qrCodeYPosition))
