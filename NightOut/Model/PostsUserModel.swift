import Foundation

// Modelo para cada post
struct PostUserModel: Codable {
    
    init(description: String? = nil, postID: String, postImage: String? = nil, publisherId: String, location: String? = nil, isFromUser: Bool? = nil, timestamp: Int64? = nil) {
        self.description = description
        self.postID = postID
        self.postImage = postImage
        self.publisherId = publisherId
        self.location = location
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
    
    let description: String?
    let postID: String
    let postImage: String?
    let publisherId: String
    let location: String?
    let isFromUser: Bool?
    let timestamp: Int64?
    
    
    // Mapear claves JSON a propiedades Swift
    enum CodingKeys: String, CodingKey {
        case description
        case postID = "postid"
        case postImage = "postimage"
        case publisherId = "publisher"
        case location = "location"
        case isFromUser = "isFromUser"
        case timestamp
    }
    
    // Decodificación personalizada para manejar la ausencia de timestamp
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            description = try container.decodeIfPresent(String.self, forKey: .description)
            postID = try container.decode(String.self, forKey: .postID)
            postImage = try container.decodeIfPresent(String.self, forKey: .postImage)
            publisherId = try container.decode(String.self, forKey: .publisherId)
            location = try container.decodeIfPresent(String.self, forKey: .location)
            isFromUser = try container.decodeIfPresent(Bool.self, forKey: .isFromUser)
            timestamp = try container.decodeIfPresent(Int64.self, forKey: .timestamp) ?? 0  // Si falta, pone 0
        }
}
