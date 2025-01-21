import Foundation

struct NotificationModel: Codable {
    var ispost: Bool
    var postid: String
    var text: String
    var userid: String
    var date: String
    
    init(ispost: Bool, postid: String, text: String, userid: String,  date: String?) {
        self.ispost = ispost
        self.postid = postid
        self.text = text
        self.userid = userid
        self.date = date ?? ""
    }
}

