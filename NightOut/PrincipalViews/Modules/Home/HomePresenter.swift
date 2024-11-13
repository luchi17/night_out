

enum HomeSelectedTab {
    case feed
    case map
    
    var title: String {
        switch self {
        case .feed:
            return "feed"
        case .map:
            return "mapa"
        }
    }
}
