import Foundation

/// Conforming to the PersistenceModelInterface Protocol
/// =======================================
public protocol IPersistenceModel: Codable {
    var retainOriginalIndex: Bool { get set }
    var index: String? { get set }
}

public extension IPersistenceModel { }

extension IPersistenceModel {
    typealias JSONString = String

    func toJSON() throws -> JSONString {
        do {
            let jsonData = try JSONEncoder().encode(self)
            let jsonString = JSONString(data: jsonData, encoding: .utf8)!
            return jsonString
        } catch let error {
            throw PersistenceModelError.couldNotBeEncoded(error)
        }
    }

    func fromJSON(_ jsonString: JSONString) throws -> Self {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw PersistenceModelError.dataCorrupted
        }
        do {
            return try JSONDecoder().decode(Self.self, from: jsonData)
        } catch let error {
            throw PersistenceModelError.couldNotBeDecoded(error)
        }
    }

    static func fromJSON(_ jsonString: JSONString) throws -> Self {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw PersistenceModelError.dataCorrupted
        }
        do {
            return try JSONDecoder().decode(Self.self, from: jsonData)
        } catch let error {
            throw PersistenceModelError.couldNotBeDecoded(error)
        }
    }
}
