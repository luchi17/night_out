import Foundation

class Utils {
    // ascending: comments
    // descending not y posts 
    static func sortByDate<T>(objects: [T], dateExtractor: (T) -> String, ascending: Bool) -> [T] {
        let dateFormatter = ISO8601DateFormatter()
        return objects.sorted { obj1, obj2 in
            guard let date1 = dateFormatter.date(from: dateExtractor(obj1)),
                  let date2 = dateFormatter.date(from: dateExtractor(obj2)) else {
                return false // Si las fechas no se pueden convertir, se mantienen en el orden original
            }
            return ascending ? date1 < date2 : date1 > date2
        }
    }

}
