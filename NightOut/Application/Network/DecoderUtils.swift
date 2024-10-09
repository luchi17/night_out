import Foundation

// sourcery: AutoMockable
public protocol ServiceDecoderType {
    func decodeTo<D: Decodable>(data: Data, type: D.Type, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy) -> Result<D, NetworkErrorType>

    func decodeTo<D: Decodable>(data: Data, type: D.Type, withCustomPath customPath: String?) -> Result<D, NetworkErrorType>
}

public extension ServiceDecoderType {
    func decodeTo<D: Decodable>(
        data: Data,
        type: D.Type,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
    ) -> Result<D, NetworkErrorType> {
        decodeTo(data: data, type: type, dateDecodingStrategy: dateDecodingStrategy)
    }
}

public final class ServiceDecoder: ServiceDecoderType {
    public static let shared: ServiceDecoderType = ServiceDecoder()

    public func decodeTo<D: Decodable>(
        data: Data,
        type: D.Type,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
    ) -> Result<D, NetworkErrorType> {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = dateDecodingStrategy
            return .success(try decoder.decode(D.self, from: data))
        } catch {
            return .failure(
                .decodeFailed(
                    error: error,
                    decodingType: type
                )
            )
        }
    }

    public func decodeTo<D>(data: Data, type: D.Type, withCustomPath customPath: String?) -> Result<D, NetworkErrorType> where D: Decodable {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                return .failure(
                    .unknown(description: "Unable to decode nil json after serialization")
                )
            }
            return json.map(type, atKeyPath: customPath)
        } catch {
            return .failure(
                .decodeFailed(
                    error: error,
                    decodingType: type
                )
            )
        }
    }
}
