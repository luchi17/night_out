import Foundation

func structToDictionary<T: Codable>(_ value: T) -> [String: Any]? {
    let encoder = JSONEncoder()
    
    // Intenta convertir la estructura a Data usando JSONEncoder
    guard let data = try? encoder.encode(value) else {
        return nil
    }
    
    // Intenta convertir los datos JSON a un diccionario
    guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
          let dictionary = json as? [String: Any] else {
        return nil
    }
    
    return dictionary
}
