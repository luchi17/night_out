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

// Modelo para manejar el nodo raíz "Follow"
struct FollowRootModel: Codable {
    let follows: [String: FollowModel]
    
    // Decodificación personalizada para manejar claves dinámicas
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var tempFollows: [String: FollowModel] = [:]
        
        for key in container.allKeys {
            let followRelations = try container.decode(FollowModel.self, forKey: key)
            tempFollows[key.stringValue] = followRelations
        }
        
        self.follows = tempFollows
    }
    
    // Codificación personalizada para manejar claves dinámicas
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        for (key, followRelations) in follows {
            guard let codingKey = DynamicCodingKey(stringValue: key) else {
                continue
            }
            try container.encode(followRelations, forKey: codingKey)
        }
    }
}
