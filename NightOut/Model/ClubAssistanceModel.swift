import Foundation

struct ClubAssistance: Codable {
    let uid: String
    let gender: String?
    
    enum CodingKeys: String, CodingKey {
        case uid
        case gender
    }
}
