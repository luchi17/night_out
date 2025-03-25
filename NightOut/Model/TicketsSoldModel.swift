import Foundation

struct TicketModel: Codable {
    let correo: String?
    let nombre: String?
    let discoteca: String?
    let evento: String?
    let fecha: String?
    let numeroTicket: String?
    let precio: String?
    let qrCodeBase64: String?
    let qrText: String?
    let tipoDeEntrada: String?
    let validado: Bool?
}
