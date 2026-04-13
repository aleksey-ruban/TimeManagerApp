import Foundation

public struct Parser<Output: Decodable> {
    private let decoder: JSONDecoder
    private let rootKeyPath: String?

    public init(
        decoder: JSONDecoder = JSONDecoder(),
        rootKeyPath: String? = nil
    ) {
        self.decoder = decoder
        self.rootKeyPath = rootKeyPath
    }

    public func parse(_ data: Data) throws -> Output {
        let payload = try extractPayload(from: data)
        return try decoder.decode(Output.self, from: payload)
    }

    private func extractPayload(from data: Data) throws -> Data {
        guard let rootKeyPath, rootKeyPath.isEmpty == false else {
            return data
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let keyPathComponents = rootKeyPath
            .split(separator: ".")
            .map(String.init)

        let nestedObject = try keyPathComponents.reduce(jsonObject) { currentObject, key in
            guard let dictionary = currentObject as? [String: Any] else {
                throw ParserError.invalidRootObject(rootKeyPath)
            }

            guard let nextObject = dictionary[key] else {
                throw ParserError.missingKey(rootKeyPath)
            }

            return nextObject
        }

        guard JSONSerialization.isValidJSONObject(nestedObject) else {
            throw ParserError.invalidJSONObject(rootKeyPath)
        }

        return try JSONSerialization.data(withJSONObject: nestedObject)
    }
}

public enum ParserError: Error, Equatable {
    case invalidRootObject(String)
    case missingKey(String)
    case invalidJSONObject(String)
}
