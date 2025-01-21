import Foundation

struct CommentModel: Codable {
    let comment: String
    let publisher: String
    let date: String
    
    init(comment: String, publisher: String, date: String) {
        self.comment = comment
        self.publisher = publisher
        self.date = date
    }
}
