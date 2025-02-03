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
    
    var genderType: Gender? {
        if gender == "Male" {
            return .male
        } else if gender == "Female" {
            return .female
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
    
    init(uid: String, fullname: String, username: String, email: String, gender: String? = nil, image: String? = nil, fcm_token: String? = nil, attendingClub: String? = nil, misLigas: [String : Bool]? = nil, profile: String? = nil) {
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
    }
}

enum Gender {
    case male
    case female
    
    var title: String {
        switch self {
        case .male:
            return "Mujer"
        case .female:
            return "Hombre"
        }
    }
    
    var firebaseTitle: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        }
    }
}

enum ProfileType {
    case privateProfile
    case publicProfile
}
