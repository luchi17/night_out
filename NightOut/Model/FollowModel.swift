import Foundation

// Estructura para representar las relaciones de 'Followers' y 'Following'
struct FollowModel: Codable {
    let followers: [String: Bool]?
    let following: [String: Bool]?
    
    // Mapear las claves 'Followers' y 'Following' de forma explícita
    enum CodingKeys: String, CodingKey {
        case followers = "Followers"
        case following = "Following"
    }
}
