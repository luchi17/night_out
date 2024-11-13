//
//  Dictionary+Extensions.swift
//  
//
//  Created by Pablo.Sanchez on 18/8/22.
//

import Foundation

typealias JSON = [String: Any]

extension Dictionary where Key == String, Value: Any {
    func map<D: Decodable>(_ type: D.Type, atKeyPath keyPath: String? = nil) -> Result<D, NetworkErrorType> {
        let jsonData: Data
        let decoder = JSONDecoder()

        if let keyPath = keyPath {
            guard let jsonObject = self[keyPath: KeyPath(keyPath)] else {
                return .failure(NetworkErrorType.unknown(description: "Malformed JSON"))
            }

            if let data = try? serializeToData(jsonObject) {
                jsonData = data
            } else {
                let wrappedJsonObject = ["value": jsonObject]
                guard let data = try? serializeToData(wrappedJsonObject) else {
                    return .failure(NetworkErrorType.unknown(description: "Malformed JSON"))
                }
                do {
                    return .success(try decoder.decode(DecodableWrapper<D>.self, from: data).value)
                } catch let error {
                    return .failure(
                        .decodeFailed(
                            error: error,
                            decodingType: type
                        )
                    )
                }
            }
        } else if let data = try? serializeToData(self) {
            jsonData = data
        } else {
            return .failure(NetworkErrorType.unknown(description: "Malformed JSON"))
        }
        do {
            return .success(try decoder.decode(D.self, from: jsonData))
        } catch let error {
            return .failure(
                .decodeFailed(
                    error: error,
                    decodingType: type
                )
            )
        }
    }
}

private extension Dictionary where Key == String, Value: Any {
    private struct DecodableWrapper<D: Decodable>: Decodable {
        let value: D
    }
}

private func serializeToData(_ object: Any) throws -> Data? {
    guard JSONSerialization.isValidJSONObject(object) else { return nil }
    do {
        return try JSONSerialization.data(withJSONObject: object)
    } catch {
        throw NetworkErrorType.unknown(description: "Malformed JSON")
    }
}

// MARK: - KeyPath

// Credits for this dictionary extension for Ole Begemann => https://oleb.net/blog/2017/01/dictionary-key-paths/
struct KeyPath {
    var segments: [String]

    var isEmpty: Bool { return segments.isEmpty }
    var path: String {
        return segments.joined(separator: ".")
    }

    func headAndTail() -> (head: String, tail: KeyPath)? {
        guard !isEmpty else { return nil }
        var tail = segments
        let head = tail.removeFirst()
        return (head, KeyPath(segments: tail))
    }
}

extension KeyPath {
    init(_ string: String) {
        segments = string.components(separatedBy: ".")
    }
}

extension KeyPath: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)
    }

    init(unicodeScalarLiteral value: String) {
        self.init(value)
    }

    init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
}

extension Dictionary where Key == String {
    subscript(keyPath keyPath: KeyPath) -> Any? {
        switch keyPath.headAndTail() {
        case nil:
            // key path is empty.
            return nil
        case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
            // Reached the end of the key path.
            return self[head]
        case let (head, remainingKeyPath)?:
            // Key path has a tail we need to traverse.
            switch self[head] {
            case let nestedDict as [Key: Any]:
                // Next nest level is a dictionary.
                // Start over with remaining key path.
                return nestedDict[keyPath: remainingKeyPath]
            default:
                // Next nest level isn't a dictionary.
                // Invalid key path, abort.
                return nil
            }
        }
    }

    func value<T>(forKeyPath path: KeyPath, ofClass: T.Type) -> T? {
        return self[keyPath: path] as? T
    }
}
