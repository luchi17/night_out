import Foundation

class Utils {
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
    
    static func formatDate(_ dateString: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd-MM-yyyy"
        inputFormatter.locale = Locale(identifier: "es_ES")

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d 'de' MMMM"
        outputFormatter.locale = Locale(identifier: "es_ES")

        if let date = inputFormatter.date(from: dateString) {
                let formattedDate = outputFormatter.string(from: date)
                // Convertir el mes a mayúsculas
                let components = formattedDate.split(separator: " ")
                if components.count == 3 {
                    // Crear una nueva lista de componentes con el mes en mayúsculas
                    var result = components.map { String($0) }
                    result[2] = result[2].capitalized
                    return result.joined(separator: " ")
                }
                return formattedDate
            }
            return nil
    }
}
