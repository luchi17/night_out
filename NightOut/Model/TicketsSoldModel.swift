import Foundation

// Modelo para los datos de cada ticket
struct TicketModel: Codable {
    let apellido: String?
    let correo: String?
    let descripcion: String?
    let discoteca: String?
    let dni: String?
    let evento: String?
    let fecha: String?
    let nombre: String?
    let numeroTicket: String?
    let precio: String?
    let qrCodeBase64: String?
}

// Modelo para manejar el JSON completo con claves dinámicas en el nivel raíz
struct TicketsRoot: Codable {
    let tickets: [String: TicketModel]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var tempTickets: [String: TicketModel] = [:]
        
        for key in container.allKeys {
            let ticket = try container.decode(TicketModel.self, forKey: key)
            tempTickets[key.stringValue] = ticket
        }
        
        self.tickets = tempTickets
    }
    
    // Codificación a JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        for (key, ticket) in tickets {
            guard let codingKey = DynamicCodingKey(stringValue: key) else {
                continue
            }
            try container.encode(ticket, forKey: codingKey)
        }
    }
}
