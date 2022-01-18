import Foundation

public protocol ILocalContext {
    func get<T: IPersistenceModel>(_ objectType: T.Type, storage: LocalSupportedStorage) -> T?
    func get<T: IPersistenceModel>(_ objectType: T.Type, storage: LocalSupportedStorage, index: String) -> T?
    func get<T: IPersistenceModel>(arrayOf objectType: T.Type, storage: LocalSupportedStorage) -> [T]
    func save<T: IPersistenceModel>(_ object: inout T, storage: LocalSupportedStorage) throws
    func delete<T: IPersistenceModel>(_ object: T, storage: LocalSupportedStorage) throws
    func delete<T: IPersistenceModel>(by objectType: T.Type, storage: LocalSupportedStorage) throws
    func deleteAllObjects(in storage: [LocalSupportedStorage]) throws
}
