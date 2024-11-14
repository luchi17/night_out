import Foundation


struct CompanyUsersModel: Codable {
    let users: [String: CompanyModel]  // Un diccionario de usuarios donde la clave es el UID

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        var usersDict = [String: CompanyModel]()
        
        for key in container.allKeys {
            let user = try container.decode(CompanyModel.self, forKey: key)
            usersDict[key.stringValue] = user
        }
        self.users = usersDict
    }
}

struct CompanyModel: Codable {
    var email: String = ""
    var endTime: String? = ""
    var selectedTag: String? = ""
    var fullname: String? = ""
    var username: String? = ""
    var imageUrl: String?
    var location: String? = ""
    var startTime: String? = ""
    var uid: String = ""
    var entradas: [String: EntradasPorFecha]?
    var payment: PaymentMethodModel?
    
    enum CodingKeys: String, CodingKey {
            case entradas = "Entradas"
            case email
            case fullname
            case location
            case selectedTag = "selected_tag"
            case startTime = "start_time"
            case endTime = "end_time"
            case uid
            case username
            case payment = "Metodos_De_Pago"
            case imageUrl = "image"
        }
}

struct EntradaModel: Codable {
    let capacity: String
    let description: String?
    let fecha: String?
    let imageURL: String?
    let name: String?
    let price: String

    enum CodingKeys: String, CodingKey {
        case capacity
        case description
        case fecha
        case imageURL = "image_url"
        case name
        case price
    }
}

// Modelo para las entradas agrupadas por fecha
struct EntradasPorFecha: Codable {
    let entradas: [String: EntradaModel]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        var entries = [String: EntradaModel]()
        
        for key in container.allKeys {
            entries[key.stringValue] = try container.decode(EntradaModel.self, forKey: key)
        }
        self.entradas = entries
    }
}

struct PaymentMethodModel: Codable {
    var accountHolderName: String = ""
    var accountType: String = ""
    var addressLine: String = ""
    var city: String = ""
    var country: String? = ""
    var dob: String? = ""
    var iban: String? = ""
    var postalCode: String? = ""
    var swift: String? = ""
    var taxId: String? = ""
}

// DynamicKey permite decodificar claves dinámicas en un diccionario
struct DynamicKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }
}
