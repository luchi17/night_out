import Foundation

// Modelo para cada post
struct PostUserModel: Codable {
    let description: String
    let postID: String
    let postImage: String
    let publisher: String
    
    // Mapear claves JSON a propiedades Swift
    enum CodingKeys: String, CodingKey {
        case description
        case postID = "postid"
        case postImage = "postimage"
        case publisher
    }
}

// Modelo para el nodo raíz "Posts"
struct PostsUser: Codable {
    let posts: [String: PostUserModel]
    
    
    // Decodificación personalizada para manejar claves dinámicas
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var tempPosts: [String: PostUserModel] = [:]
        
        for key in container.allKeys {
            let post = try container.decode(PostUserModel.self, forKey: key)
            tempPosts[key.stringValue] = post
        }
        
        self.posts = tempPosts
    }
    
    // Codificación personalizada para manejar claves dinámicas
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        
        for (key, post) in posts {
            guard let codingKey = DynamicCodingKey(stringValue: key) else {
                continue
            }
            try container.encode(post, forKey: codingKey)
        }
    }
}
