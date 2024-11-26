import Foundation

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
}

enum Gender {
    case male
    case female
    
    var title: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        }
    }
}
