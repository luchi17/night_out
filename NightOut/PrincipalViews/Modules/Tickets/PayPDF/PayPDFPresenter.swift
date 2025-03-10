import Combine
import SwiftUI
import Firebase
import PDFKit
import CoreImage
import UIKit
import FirebaseDatabase

struct TicketPDFModel: Hashable {
    let name: String
    let pdf: URL?
    let ticketNumber: String
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
        let goBack: VoidClosure
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
                
                if FirebaseServiceImpl.shared.getImUser() {
                    presenter.moveUserToNewAssistance {
                        presenter.addUsersToAssistance(
                            clubId: presenter.viewModel.model.companyuid,
                            date: presenter.viewModel.model.date,
                            personDataList: presenter.viewModel.model.personDataList
                        )
                       
                        presenter.sendNotification(eventText: presenter.viewModel.model.nameEvent)
                    }
                }

                for user in presenter.viewModel.model.personDataList {
                    print("generando PDF para \(user.name)")
                    
                    presenter.generatePdf(person: user) { data in
                        
                        presenter.viewModel.loading = false
                        
                        let ticket = TicketPDFModel(
                            name: user.name,
                            pdf: data.0,
                            ticketNumber: data.1
                        )
                        presenter.viewModel.ticketsList.append(ticket)
                    }
                }
            }
            .store(in: &cancellables)
        
        input
            .downloadPdf
            .withUnretained(self)
            .sink { presenter, ticket in
                PDFDownloader.shared.descargarYMostrarPDF(
                    desde: ticket.pdf,
                    name: ticket.name,
                    numeroTicket: ticket.ticketNumber) { [weak self] toast in
                        DispatchQueue.main.async {
                            self?.viewModel.toast = toast
                        }
                    }
            }
            .store(in: &cancellables)
        
        input
            .goBack
            .withUnretained(self)
            .sink { presenter, _ in
                presenter.actions.goBack()
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
    
    func generatePdf(person: PersonTicketData, callback: @escaping ((URL?, String)) -> Void) {
        
        guard let userUID = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            callback((nil, ""))
            return
        }
        
        let pdfFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("EventTickets")
        
        if !FileManager.default.fileExists(atPath: pdfFolder.path) {
            do {
                try FileManager.default.createDirectory(at: pdfFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                callback((nil, ""))
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
            lastTicketNumberRef.setValue(newTicketNumber)
            
            // Generate the QR Code
            guard let qrCodeImage = self.generateQRCode(string: numeroTicket) else {
                print("No se pudo crear el qrCodeBitmap")
                callback((nil, ""))
                return
            }
            
            let qrCodeBase64 = self.encodeToBase64(bitmap: qrCodeImage)
            
            let ticketData: [String: Any] = [
                "nombre": person.name,
                "correo": person.email,
                "evento": self.viewModel.model.nameEvent,
                "tipo de entrada": self.viewModel.model.type,
                "precio": String(self.viewModel.model.price),
                "fecha": self.viewModel.model.date,
                "discoteca": self.viewModel.model.companyuid,
                "qrText": numeroTicket,
                "numeroTicket": numeroTicket,
                "qrCodeBase64": qrCodeBase64
            ]
            
            if FirebaseServiceImpl.shared.getImUser() {
                let userTicketRef = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userUID).child("MisEntradas").child(numeroTicket)
                userTicketRef.setValue(ticketData)
            } else {
                let userTicketRef = FirebaseServiceImpl.shared.getCompanyInDatabaseFrom(uid: userUID).child("MisEntradas").child(numeroTicket)
                userTicketRef.setValue(ticketData)
            }
            
            // Guardar en Firebase en el nodo de la empresa (TicketsVendidos)
            databaseReference.child(numeroTicket).setValue(ticketData)
            
            let companyUsersRef = FirebaseServiceImpl.shared
                .getCompanyInDatabaseFrom(uid: self.viewModel.model.companyuid)
                .child("username")
            
            companyUsersRef.getData { [weak self] (error, snapshot) in
                guard error == nil else {
                    print("Error al obtener el username: \(error!.localizedDescription)")
                    return
                }
                
                let companyUsername = snapshot?.value as? String ?? "Nombre no disponible"
                
                self?.createPDF(
                    numeroTicket: numeroTicket,
                    person: person,
                    qrCodeImage: qrCodeImage,
                    companyUsername: companyUsername,
                    callback: { url in
                        callback((url, numeroTicket))
                    }
                )
            }
        }
    }
    
    func createPDF(numeroTicket: String, person: PersonTicketData, qrCodeImage: UIImage, companyUsername: String, callback: @escaping (URL?) -> Void) {
        // Crear el archivo PDF
        
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
        
        let pdfFilename = pdfFolder.appendingPathComponent("ticket_\(person.name)_\(numeroTicket).pdf")
        
        // Dibuja la imagen de fondo
        guard let backgroundImage = UIImage(named: "pdf_view") else {
            print("no backgroundImage")
            callback(nil)
            return
        }
        
        // Obtener las dimensiones de la imagen para usar como tamaño de página
        let imageSize = backgroundImage.size
        
        // Crear el PDF context
        UIGraphicsBeginPDFContextToFile(pdfFilename.path, .zero, nil)
        
        // Comienza una nueva página con el tamaño de la imagen
        let pageRect = CGRect(origin: .zero, size: imageSize)
        
        UIGraphicsBeginPDFPageWithInfo(pageRect, nil)

        // Dibujar la imagen en el contexto con las dimensiones exactas de la página
        backgroundImage.draw(in: pageRect)
        
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
        self.addText(label: "Nombre: ", value: "\(person.name)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Correo: ", value: "\(person.email)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Número de Ticket: ", value: "\(numeroTicket)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Fecha: ", value: "\(self.viewModel.model.date)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Precio: ", value: "\(self.viewModel.model.price) euros", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Evento: ", value: "\(self.viewModel.model.nameEvent.capitalized)", at: CGPoint(x: xposition, y: yPosition))
        
        yPosition += 15
        self.addText(label: "Tipo de entrada: ", value: "\(self.viewModel.model.type)", at: CGPoint(x: xposition, y: yPosition))
        
        
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
        let boldText = NSAttributedString(string: label, attributes: boldAttributes)
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


    func addUsersToAssistance(clubId: String, date: String, personDataList: [PersonTicketData]) {
        
        let dbRef = Database.database().reference()
       
        for person in personDataList {

            let email = person.email.lowercased()
            
            dbRef.child("Users")
                .queryOrdered(byChild: "email")
                .queryEqual(toValue: email).observeSingleEvent(of: .value) { snapshot in
                    
                    if snapshot.exists(), let userSnapshot = snapshot.children.allObjects.first as? DataSnapshot {
                        
                        let userId = userSnapshot.key
                        let gender = userSnapshot.childSnapshot(forPath: "gender").value as? String ?? "Desconocido"
                        
                        let assistanceRef = dbRef.child("Club").child(clubId).child("Assistance").child(date).child(userId)
                        let attendingClubRef = dbRef.child("Users").child(userId).child("attendingClub")

                        let userMap: [String: Any] = [
                            "uid": userId,
                            "gender": gender,
                            "entry": true // 🔹 Se añade "entry: true"
                        ]

                        assistanceRef.setValue(userMap) { error, _ in
                            if let error = error {
                                print("Error al añadir asistencia para \(person.name): \(error.localizedDescription)")
                            } else {
                                attendingClubRef.setValue(clubId)
                                print("Usuario \(person.name) añadido a la asistencia de \(clubId) en la fecha \(date) con entry=true")
                            }
                        }
                    } else {
                        print("No se encontró UID para \(person.name) con correo \(email)")
                    }
                } withCancel: { error in
                    print("Error al buscar UID para \(person.name): \(error.localizedDescription)")
                }
        }
    }

    func moveUserToNewAssistance(onComplete: @escaping () -> Void) {
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            print("Usuario no autenticado")
            onComplete()
            return
        }

        let clubsRef = FirebaseServiceImpl.shared.getClub()

        clubsRef.observeSingleEvent(of: .value) { snapshot in
            
            for clubSnapshot in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                
                guard let clubId = clubSnapshot.key as String? else { continue }
                
                let assistanceRef = clubSnapshot.childSnapshot(forPath: "Assistance")

                for dateSnapshot in assistanceRef.children.allObjects as? [DataSnapshot] ?? [] {
                    
                    guard let date = dateSnapshot.key as String? else { continue }
                    
                    let userRef = dateSnapshot.childSnapshot(forPath: userId)

                    if userRef.exists() {
                        
                        let entryRef = userRef.childSnapshot(forPath: "entry").value as? Bool

                        if entryRef == true {
                            print("El usuario tiene entry=true, no se elimina.")
                            onComplete()
                            return
                        }

                        // 🔹 Si "entry" es false o no existe, eliminar al usuario
                        clubsRef.child(clubId).child("Assistance").child(date).child(userId)
                            .removeValue { error, _ in
                                if let error = error {
                                    print("Error al eliminar asistencia: \(error.localizedDescription)")
                                } else {
                                    print("Usuario eliminado de la asistencia de \(clubId) en la fecha \(date) porque entry era false o no existía")
                                }
                            }

                        // Solo necesitamos eliminar una vez, así que llamamos a onComplete() y salimos
                        onComplete()
                        return
                    }
                }
            }
            // 🔹 Si el usuario no estaba en ningún club, simplemente llamamos a onComplete()
            onComplete()
        } withCancel: { error in
            print("Error al buscar asistencia previa: \(error.localizedDescription)")
            onComplete()
        }
    }

    func sendNotification(eventText: String) {
        guard let userId = FirebaseServiceImpl.shared.getCurrentUserUid() else {
            print("Usuario no autenticado")
            return
        }

        // 🔹 Obtener el username del usuario actual
        let userRef = FirebaseServiceImpl.shared.getUserInDatabaseFrom(uid: userId)

        userRef.getData { error, snapshot in
            
            guard error == nil, let snapshot = snapshot, snapshot.exists(),
                  let username = snapshot.childSnapshot(forPath: "username").value as? String else {
                print("❌ No se encontró el username del usuario actual.")
                return
            }

            // 🔹 Buscar a los seguidores
            let followersRef = FirebaseServiceImpl.shared.getFollow().child(userId).child("Followers")

            followersRef.observeSingleEvent(of: .value) { snapshot in
                guard snapshot.exists() else {
                    print("⚠ El usuario no tiene seguidores. No se enviará ninguna notificación.")
                    return
                }

                for followerSnapshot in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                    guard let followerId = followerSnapshot.key as String? else { continue }

                    // 🔹 Subir la notificación con username + texto
                    let notiRef = FirebaseServiceImpl.shared.getNotifications().child(followerId)
                    let notiMap: [String: Any] = [
                        "userid": userId,
                        "text": "\(username): asistirá a \(eventText)", // 🔥 Añade el username al texto
                        "postid": "",
                        "ispost": false
                    ]

                    notiRef.childByAutoId().setValue(notiMap) { error, _ in
                        if let error = error {
                            print("❌ Error al enviar notificación a \(followerId): \(error.localizedDescription)")
                        } else {
                            print("✅ Notificación enviada con éxito a \(followerId)")
                        }
                    }
                }
            } withCancel: { error in
                print("❌ Error al obtener seguidores: \(error.localizedDescription)")
            }
        }
    }


    
}
