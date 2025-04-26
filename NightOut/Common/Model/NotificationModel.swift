import Foundation

struct NotificationModel: Codable {
    var ispost: Bool
    var postid: String
    var text: String
    var userid: String
    var timestamp: Int64?
    
    init(ispost: Bool, postid: String, text: String, userid: String, timestamp: Int64) {
        self.ispost = ispost
        self.postid = postid
        self.text = text
        self.userid = userid
        self.timestamp = timestamp
    }
}

