import Foundation

struct MessageModel: Codable {
    let id: String
    let message: String
    let sender: String
    let timestamp: Int
}
