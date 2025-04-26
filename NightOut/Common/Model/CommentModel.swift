import Foundation

struct CommentModel: Codable {
    let comment: String
    let publisher: String
    
    init(comment: String, publisher: String) {
        self.comment = comment
        self.publisher = publisher
    }
}
