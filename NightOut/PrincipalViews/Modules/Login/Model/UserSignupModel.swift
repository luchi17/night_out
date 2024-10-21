import Foundation

struct UserModel: Codable {
    var uid: String = ""
    var fullName: String = ""
    var userName: String = ""
    var email: String = ""
    var gender: String?
    var image: String?
    var fcm_token: String?
}
