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
    
    init(uid: String, fullname: String, username: String, email: String, gender: String? = nil, image: String? = nil, fcm_token: String? = nil, attendingClub: String? = nil, misLigas: [String : Bool]? = nil) {
        self.uid = uid
        self.fullname = fullname
        self.username = username
        self.email = email
        self.gender = gender
        self.image = image
        self.fcm_token = fcm_token
        self.attendingClub = attendingClub
        self.misLigas = misLigas
    }
    
//    init?(snapshot: DataSnapshot) {
//        guard let value = snapshot.value as? [String: Any],
//              let uid = value["uid"] as? String,
//              let username = value["username"] as? String else {
//            return nil
//        }
//        self._id = id
//        self.username = username
//    }
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
