import Foundation

struct UserModel: Codable {
    var fullName: String
    var userName: String
    var email: String
    var gender: String?
    var uid: String
    var image: String?
    var fcm_token: String?
}
