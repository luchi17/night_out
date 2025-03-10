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
    
    // Función para generar el código QR
    func generateQRCode(string: String) -> UIImage? {
        // Crear un objeto CIImage con el texto dado
        let data = string.data(using: .utf8)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("Q", forKey: "inputCorrectionLevel")
            
            // Obtener la imagen resultante
            if let qrCodeImage = filter.outputImage {
                // Escalar la imagen para que sea más legible
                let scaleX = 150 / qrCodeImage.extent.size.width
                let scaleY = 150 / qrCodeImage.extent.size.height
                let transformedImage = qrCodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                
                // Convertir CIImage a UIImage
                return UIImage(ciImage: transformedImage)
            }
        }
        return nil
    }
    
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
            guard let qrCodeBitmap = self.generateQRCode(string: numeroTicket) else {
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
        
        // Dibuja la imagen de fondo
        guard let backgroundImage = UIImage(named: "pdf_view") else {
            print("no backgroundImage")
            return
        }
        
        // Obtener las dimensiones de la imagen para usar como tamaño de página
        let imageSize = backgroundImage.size
        
        // Crear el PDF context
        UIGraphicsBeginPDFContextToFile(pdfFilename.path, .zero, nil)
        
        // Comienza una nueva página con el tamaño de la imagen
        let pageRect = CGRect(origin: .zero, size: imageSize)
        UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
        
        // Obtener el contexto de gráficos
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Dibujar la imagen en el contexto con las dimensiones exactas de la página
        backgroundImage.draw(in: pageRect)
        
        
        // Generate the QR Code
        guard let qrCodeImage = self.generateQRCode(string: numeroTicket) else {
            print("No se pudo crear el qrCodeBitmap".uppercased())
            return
        }
        // FIREBASE
        //        let qrCodeBase64 = self.encodeToBase64(bitmap: qrCodeBitmap)
        
        let qrSizeHeight = (imageSize.height / 2)
        
        let qrRect = CGRect(
            x: (pageRect.width - qrSizeHeight) / 2,  // Centrado horizontalmente
            y: (pageRect.height - qrSizeHeight) / 2, // Centrado verticalmente
            width: qrSizeHeight,
            height: qrSizeHeight
        )
        
        // Dibujar el QR
        qrCodeImage.draw(in: qrRect)
        
        //ADD TEXT
        
        let xposition = 10
        var yPosition = 10
        
        // HEADER
        let headerText = "EVENTO: \(self.viewModel.model.nameEvent.capitalized)  DISCOTECA: \(companyUsername.capitalized)"
        
        let eventTitleFont = UIFont.boldSystemFont(ofSize: 9)
        self.addText(label: headerText, value: "", at: CGPoint(x: xposition, y: yPosition), boldFont: eventTitleFont, boldColor: .darkBlue)

        //REST
        yPosition += 20
        self.addText(label: "Nombre", value: "\(person.name)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Correo", value: "\(person.email)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Número de Ticket", value: "\(numeroTicket)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Fecha", value: "\(self.viewModel.model.date)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Precio", value: "\(self.viewModel.model.price) euros", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Evento", value: "\(self.viewModel.model.nameEvent.capitalized)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Tipo de entrada", value: "\(self.viewModel.model.type)", at: CGPoint(x: xposition, y: yPosition))
        
        
        // FOOTER
        let footerFont = UIFont.italicSystemFont(ofSize: 7)
        
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = "Condiciones del Ticket: Este ticket es personal e intransferible. Modificaciones no permitidas."
        
        // Calcular el ancho del texto para centrarlo
        let footerTextSize = footerText.size(withAttributes: footerAttributes)
        let footerX = (pageRect.width - footerTextSize.width) / 2
        let footerY = pageRect.height - footerTextSize.height - 10
        
        // Dibujar el texto en el footer (centrado)
        footerText.draw(at: CGPoint(x: footerX, y: footerY), withAttributes: footerAttributes)
        
        // Finalizar el contexto del PDF
        UIGraphicsEndPDFContext()
        
        print("PDF guardado en: \(pdfFilename.path)")
        callback(pdfFilename)
    }
    
    func addText(
        label: String,
        value: String,
        at point: CGPoint,
        boldFont: UIFont = UIFont.boldSystemFont(ofSize: 9),
        boldColor: UIColor = UIColor.black,
        normalFont: UIFont = UIFont.systemFont(ofSize: 9),
        normalColor: UIColor = UIColor.darkGray
    ) {
        
        // Crear textos con atributos
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: boldFont,
            .foregroundColor: boldColor
        ]
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: normalFont,
            .foregroundColor: normalColor
        ]
        
        // Crear los textos en negrita y normal
        let boldText = NSAttributedString(string: "\(label): ", attributes: boldAttributes)
        let normalText = NSAttributedString(string: value, attributes: normalAttributes)
        
        // Unir ambos textos
        let combinedText = NSMutableAttributedString()
        combinedText.append(boldText)
        combinedText.append(normalText)
        
        // Dibujar el texto en el contexto
        combinedText.draw(at: point)
    }
    
    
    func encodeToBase64(bitmap: UIImage) -> String {
        guard let imageData = bitmap.pngData() else { return "" }
        return imageData.base64EncodedString()
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
