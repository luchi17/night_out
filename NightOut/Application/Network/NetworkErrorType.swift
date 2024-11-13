import Foundation

public enum NetworkErrorType: Error {
    case serverError(response: Response?)
    case unauthorized
    case noConnection
    case decodeFailed(error: Error, decodingType: Any.Type)
    case dependenciesNotInjected
    case timeout
    case unknown(description: String)
}
