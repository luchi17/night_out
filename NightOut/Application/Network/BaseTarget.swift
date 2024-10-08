import Foundation

public enum TargetMethods {
    case get
    case post
    case put
    case delete
}

public enum ParameterEncodingType {
    case url
    case json
}

public struct ParameterType: Equatable {
    public enum Value: Equatable {
        case string(String?)
        case int(Int?)
        case double(Double)
        case bool(Bool)
        case date(Date)
        case array([Value])
        case dictionary([ParameterType])
        case null

        func rawValue() -> Any {
            switch self {
            case .string(let rawString):
                return rawString ?? NSNull()
            case .int(let rawInt):
                return rawInt ?? NSNull()
            case .double(let rawDouble):
                return rawDouble
            case .bool(let rawBool):
                return rawBool
            case .array(let rawArray):
                return rawArray
            case .dictionary(let rawDictionary):
                return rawDictionary
                    .reduce(into: [String: Any]()) { result, parameter in
                        result[parameter.key] = parameter.value.rawValue()
                    }
            case .date(let rawDate):
                let formatter = ISO8601DateFormatter()
                formatter.timeZone = TimeZone.current
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter.string(from: rawDate)
            case .null:
                return NSNull()
            }
        }
    }
    public let key: String
    public let value: Value

    public init(key: String, value: Value) {
        self.key = key
        self.value = value
    }
}

extension Collection where Iterator.Element == ParameterType {
    var dictionary: [String: Any] {
        return reduceParamsToDictionary()
    }

    private func reduceParamsToDictionary() -> [String: Any] {
        return reduce(into: [String: Any]()) { result, parameter in
            result[parameter.key] = parameter.value.rawValue()
        }
    }
}

public struct BaseTarget: Equatable {
    public let baseURL: URL
    public let path: String
    public let parameters: [ParameterType]?
    public let method: TargetMethods
    public let timeout: Int
    public let parametersEncoding: ParameterEncodingType
    public let headers: [String: String]?
    public let shouldRetryLogin: Bool

    public init(
        host: Host,
        path: String,
        parameters: [ParameterType]? = nil,
        method: TargetMethods,
        customHeaders: [String: String]? = nil,
        parametersEncoding: ParameterEncodingType = .url,
        timeout: Int = 15,
        shouldRetryLogin: Bool = true
    ) {
        self.baseURL = host.baseUrl
        self.path = path
        self.method = method
        self.parametersEncoding = parametersEncoding
        self.parameters = parameters
        self.timeout = timeout
        self.headers = customHeaders
        self.shouldRetryLogin = shouldRetryLogin
    }
}


public struct Host {
    var baseUrl: URL {
        return URL(string: "")!
    }
}
