import Foundation
import Firebase

struct UserModel: Codable {
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
    let apellido: String?
    let correo: String?
    let discoteca: String?
    let dni: String?
    let evento: String?
    let fecha: String?
    let nombre: String?
    let numeroTicket: String?
    let qrCodeBase64: String?
    let qrText: String?
}

struct UserPaymentMethod: Codable {
    let cardHolderName: String
    let cardNumber: String
    let cardExpiry: String
    let cardCvv: String
    let isDefault: Bool?
}
