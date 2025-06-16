import Foundation
import AnyCodable

public struct CompanyUsersModel: Codable {
    let users: [String: CompanyModel]  // Un diccionario de usuarios donde la clave es el UID

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var usersDict = [String: CompanyModel]()
        
        for key in container.allKeys {
            let user = try container.decode(CompanyModel.self, forKey: key)
            usersDict[key.stringValue] = user
        }
        self.users = usersDict
    }
    
    public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: DynamicCodingKey.self)

            for (key, user) in users {
                guard let dynamicKey = DynamicCodingKey(stringValue: key) else {
                    continue
                }
                try container.encode(user, forKey: dynamicKey)
            }
        }
}

//Not specifying type of data with AnyCodable as I won´t decode the content of those attributes. Accessing them directly as data[""]
public struct CompanyModel: Codable {
    var email: String? = ""
    var endTime: String? = ""
    var selectedTag: String? = ""
    var fullname: String? = ""
    var username: String? = ""
    var imageUrl: String?
    var location: String? = ""
    var startTime: String? = ""
    var uid: String
    var entradas: AnyCodable?
    var payment: PaymentMethodModel?
    var ticketsSold: AnyCodable?
    var profile: String?
    var fcm_token: String?
    var MisEntradas: AnyCodable?

   
    var profileType: ProfileType {
        if profile == "private" {
            return .privateProfile
        } else {
            return .publicProfile
        }
    }
    
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
            case ticketsSold = "TicketsVendidos"
            case profile = "profile"
            case fcm_token
            case MisEntradas
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
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}
