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
