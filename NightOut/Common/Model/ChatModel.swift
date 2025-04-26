import Foundation

struct MessageModel: Codable, Identifiable {
    let id: String
    let message: String
    let sender: String
    let timestamp: Int64
}
