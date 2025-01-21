import Foundation

struct PostCompanyModel: Codable {
    var capacity: String?
    var description: String?
    var fecha: String?
    var imageURL: String?
    var name: String?
    var price: String?
    var uid: String?
    var date: String?
    
    // Mapear clave JSON a propiedad de Swift
    enum CodingKeys: String, CodingKey {
        case capacity
        case description
        case fecha
        case imageURL = "image_url"
        case name
        case price
        case uid
        case date
    }
}

struct PostsCompany: Codable {
    let events: [String: PostCompanyModel]
    
    // Decodificación personalizada para manejar claves dinámicas
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var tempEvents: [String: PostCompanyModel] = [:]
        
        for key in container.allKeys {
            let event = try container.decode(PostCompanyModel.self, forKey: key)
            tempEvents[key.stringValue] = event
        }
        
        self.events = tempEvents
    }
    
    // Codificación personalizada para manejar claves dinámicas
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        for (key, event) in events {
            guard let codingKey = DynamicCodingKey(stringValue: key) else {
                continue
            }
            try container.encode(event, forKey: codingKey)
        }
    }
}
