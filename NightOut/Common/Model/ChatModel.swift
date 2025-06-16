import Foundation

public struct MessageModel: Codable, Identifiable {
    public let id: String
    let message: String
    let sender: String
    let timestamp: Int64
}
