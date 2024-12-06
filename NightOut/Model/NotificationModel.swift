import Foundation

struct NotificationModel: Codable {
    var ispost: Bool
    var postId: String
    var text: String
    var userId: String
    
    init(ispost: Bool, postid: String, text: String, userid: String) {
        self.ispost = ispost
        self.postId = postid
        self.text = text
        self.userId = userid
    }
}

