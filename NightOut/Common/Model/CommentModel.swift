import Foundation

public struct CommentModel: Codable {
    let comment: String
    let publisher: String
    
    public init(comment: String, publisher: String) {
        self.comment = comment
        self.publisher = publisher
    }
}
