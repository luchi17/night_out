import Foundation

extension Date {
    func toIsoString() -> String {
        
        let isoDateFormatter = ISO8601DateFormatter()
        let dateString = isoDateFormatter.string(from: self)
        
        return dateString
    }
}
