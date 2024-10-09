import Combine
import Foundation

public protocol NetworkProviderType {
    func request(_ target: BaseTarget) -> AnyPublisher<Response, NetworkErrorType>
}

