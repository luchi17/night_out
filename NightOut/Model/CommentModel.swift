import Foundation


struct CommentModel: Codable {
    let comment: String
    let publisher: String
    
    init(comment: String, publisher: String) {
        self.comment = comment
        self.publisher = publisher
    }
}

// Nodo raíz que maneja claves dinámicas en múltiples niveles
struct CommentsRoot: Codable {
    let groups: [String: [String: CommentModel]]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var tempGroups: [String: [String: CommentModel]] = [:]
        
        for groupKey in container.allKeys {
            let groupContainer = try container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: groupKey)
            var comments: [String: CommentModel] = [:]
            
            for commentKey in groupContainer.allKeys {
                let comment = try groupContainer.decode(CommentModel.self, forKey: commentKey)
                comments[commentKey.stringValue] = comment
            }
            
            tempGroups[groupKey.stringValue] = comments
        }
        
        self.groups = tempGroups
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for (groupKey, comments) in groups {
            var groupContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: DynamicCodingKey(stringValue: groupKey)!)
            
            for (commentKey, comment) in comments {
                try groupContainer.encode(comment, forKey: DynamicCodingKey(stringValue: commentKey)!)
            }
        }
    }
}
