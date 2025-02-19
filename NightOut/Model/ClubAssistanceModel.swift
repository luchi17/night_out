import Foundation

struct ClubAssistance: Codable {
    let uid: String
    let gender: String?
    let tinderPhoto: String?
    let social: String?
    
    enum CodingKeys: String, CodingKey {
        case uid
        case gender
        case tinderPhoto
        case social
    }
}
