import Foundation

/// LocalSupportedStorage represents storage type where we want to save or read our local data
/// Default storage will be `sqlite`.
public enum LocalSupportedStorage: CaseIterable {
    case sqlite

    internal var persistence: ILocalStrategy {
        switch self {
        case .sqlite: return SQLiteStrategy()
        }
    }
}

public typealias IPersistence = ILocalPersistence

/// Main interface and entry point to consume the library
///
/// Exampel usage:
///
///     class Cat: IPersistenceModel {
///         let age: Int?
///     }
///
///     let persistence: IPersistence
///     let cat = persistence.get(Cat.sef)
///
public protocol ILocalPersistence {
    /// Returns a  storage object by a generic type.
    /// In that case we will reaturn only one element if they will exist. If there will be more
    /// it will be returned first matched item
    ///
    /// - Parameter objectType: Type of object what we want to fetch
    /// - Parameter storage: source of data paersistence it can be `keychain`, `sqlite`, `realm`
    /// - Returns: A generic type  which conforms to `PersistenceModelInterface` protocol
    func get<T: IPersistenceModel>(_ objectType: T.Type, storage: LocalSupportedStorage) -> T?

    /// Returns a storage object by generic type and index (primary key).
    ///
    /// - Parameter objectType: Type of object what we want to fetch
    /// - Parameter storage: source of data paersistence it can be `keychain`, `sqlite`, `realm`
    /// - Parameter index: Index of the object you want to retrieve
    /// - Returns: A generic type  which conforms to `PersistenceModelInterface` protocol
    func get<T: IPersistenceModel>(_ objectType: T.Type, storage: LocalSupportedStorage, index: String) -> T?

    /// Returns an array of storage objects
    ///
    /// - Parameter objectType: Type of object what we want to fetch
    /// - Parameter storage: source of data paersistence it can be `keychain`, `sqlite`
    /// - Returns: A generic type array  which conforms to `PersistenceModelInterface` protocol
    func get<T: IPersistenceModel>(arrayOf objectType: T.Type, storage: LocalSupportedStorage) -> [T]
    func save<T: IPersistenceModel>(_ object: inout T, storage: LocalSupportedStorage) throws
    func delete<T: IPersistenceModel>(_ object: T, storage: LocalSupportedStorage) throws
    func delete<T: IPersistenceModel>(by objectType: T.Type, storage: LocalSupportedStorage) throws
    func deleteAllObjects(in storage: [LocalSupportedStorage]) throws
}

public extension ILocalPersistence {
    func get<T: IPersistenceModel>(_ objectType: T.Type, index: String) -> T? {
        return get(objectType, storage: .sqlite, index: index)
    }

    func get<T: IPersistenceModel>(object objectType: T.Type) -> T? {
        return get(objectType, storage: .sqlite)
    }

    func get<T: IPersistenceModel>(arrayOf objectType: T.Type) -> [T] {
        return get(arrayOf: objectType, storage: .sqlite)
    }

    func save<T: IPersistenceModel>(_ object: inout T) throws {
        try save(&object, storage: .sqlite)
    }

    func delete<T: IPersistenceModel>(_ object: T) throws {
        try delete(object, storage: .sqlite)
    }

    func delete<T: IPersistenceModel>(by objectType: T.Type) throws {
        try delete(by: objectType, storage: .sqlite)
    }

    func deleteAllObjects(in storage: [LocalSupportedStorage] = [.sqlite] ) throws {
        try deleteAllObjects(in: [.sqlite])
    }
}
