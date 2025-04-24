import Foundation

public struct FollowModel: Codable {
    let followers: [String: Bool]?
    let following: [String: Bool]?
    let pending: [String: Bool]?

    enum CodingKeys: String, CodingKey {
        case followers = "Followers"
        case following = "Following"
        case pending = "Pending"
    }
}
