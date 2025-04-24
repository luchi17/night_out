import Foundation
import Firebase

public struct UserModel: Codable {
    var uid: String = ""
    var fullname: String = ""
    var username: String = ""
    var email: String = ""
    var gender: String?
    var image: String?
    var fcm_token: String?
    var attendingClub: String?
    var misLigas: [String: Bool]?
    var profile: String?
    var Liked: [String: Bool]?
    var social: String?
    var MisCopas: Int?
    var MisEntradas: [String: EntradaUserModel]?
    var PaymentMethods: [String: UserPaymentMethod]?
    
    var genderType: Gender? {
        if gender == "Hombre" {
            return .hombre
        } else if gender == "Mujer" {
            return .mujer
        } else {
            return nil
        }
    }
    
    var profileType: ProfileType {
        if profile == "private" {
            return .privateProfile
        } else {
            return .publicProfile
        }
    }
    
    init(uid: String, fullname: String, username: String, email: String, gender: String? = nil, image: String? = nil, fcm_token: String? = nil, attendingClub: String? = nil, misLigas: [String : Bool]? = nil, profile: String? = nil, Liked: [String: Bool]? = nil, social: String? = nil, misCopas: Int = 0, misEntradas: [String: EntradaUserModel]? = nil, paymentMethods: [String: UserPaymentMethod]? = nil) {
        self.uid = uid
        self.fullname = fullname
        self.username = username
        self.email = email
        self.gender = gender
        self.image = image
        self.fcm_token = fcm_token
        self.attendingClub = attendingClub
        self.misLigas = misLigas
        self.profile = profile
        self.Liked = Liked
        self.social = social
        self.MisCopas = misCopas
        self.MisEntradas = misEntradas
        self.PaymentMethods = paymentMethods
    }
}

enum Gender {
    case hombre
    case mujer
    
    var title: String {
        switch self {
        case .hombre:
            return "Hombre"
        case .mujer:
            return "Mujer"
        }
    }
    
    var firebaseTitle: String {
        switch self {
        case .hombre:
            return "Hombre"
        case .mujer:
            return "Mujer"
        }
    }
}

enum ProfileType {
    case privateProfile
    case publicProfile
}


struct EntradaUserModel: Codable {
    let correo: String?
    let discoteca: String?
    let evento: String?
    let fecha: String?
    let nombre: String?
    let numeroTicket: String?
    let precio: Precio?
    let qrCodeBase64: String?
    let qrText: String?
    let tipoEntrada: String?
    
    enum CodingKeys: String, CodingKey {
        case correo, discoteca, evento, fecha, nombre, precio, qrText
        case numeroTicket = "numeroTicket"
        case qrCodeBase64 = "qrCodeBase64"
        case tipoEntrada = "tipo de entrada"
    }
}

enum Precio: Codable {
    case double(Double)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(Precio.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Precio debe ser un String o un Double"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

struct UserPaymentMethod: Codable {
    let cardHolderName: String
    let cardNumber: String
    let cardExpiry: String
    let cardCvv: String
    let isDefault: Bool?
}
