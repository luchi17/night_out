import Foundation
import Firebase

struct ClubAssistance: Codable {
    let uid: String
    let gender: String?
    let entry: Bool?
    
    enum CodingKeys: String, CodingKey {
        case uid
        case gender
        case entry
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: Any]
        else {
            return nil
        }
        let gender = value["gender"] as? String
        let entry = value["entry"] as? Bool
        self.uid = snapshot.key
        self.gender = gender
        self.entry = entry
    }
}
