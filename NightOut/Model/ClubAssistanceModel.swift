import Foundation

// Estructura para representar los datos de un usuario en 'Assistance'
struct AssistanceUser: Codable {
    let uid: String
    let gender: String?
    let tinderPhoto: String?
    
    // Mapeo de claves, ya que no todos los usuarios tienen la propiedad 'gender' o 'tinderPhoto'
    enum CodingKeys: String, CodingKey {
        case uid
        case gender
        case tinderPhoto
    }
}

// Estructura para representar la asistencia de un club
struct ClubAssistance: Codable {
    let assistance: [String: AssistanceUser]
    
    // Decodificación personalizada para manejar datos dinámicos
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var tempAssistance: [String: AssistanceUser] = [:]
        
        for key in container.allKeys {
            let user = try container.decode(AssistanceUser.self, forKey: key)
            tempAssistance[key.stringValue] = user
        }
        
        self.assistance = tempAssistance
    }
    
    // Codificación personalizada para manejar claves dinámicas
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        for (key, user) in assistance {
            guard let codingKey = DynamicCodingKey(stringValue: key) else {
                continue
            }
            try container.encode(user, forKey: codingKey)
        }
    }
}

// Estructura para manejar los clubes
struct ClubRoot: Codable {
    let clubs: [String: ClubAssistance]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var tempClubs: [String: ClubAssistance] = [:]
        
        for key in container.allKeys {
            let clubAssistance = try container.decode(ClubAssistance.self, forKey: key)
            tempClubs[key.stringValue] = clubAssistance
        }
        
        self.clubs = tempClubs
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        for (key, clubAssistance) in clubs {
            guard let codingKey = DynamicCodingKey(stringValue: key) else {
                continue
            }
            try container.encode(clubAssistance, forKey: codingKey)
        }
    }
}
