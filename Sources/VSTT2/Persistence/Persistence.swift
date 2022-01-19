import Foundation

public final class Persistence: ILocalPersistence {
    typealias ContextInterface = ILocalContext

    private var context: ContextInterface? = StrategyContext()

    public init() {}

    internal convenience init(context: ContextInterface = StrategyContext()) {
        self.init()
        self.context = context
    }

    public func get<T>(_ objectType: T.Type, storage: LocalSupportedStorage) -> T? where T: IPersistenceModel {
        return context?.get(objectType, storage: storage)
    }

    public func get<T>(_ objectType: T.Type, storage: LocalSupportedStorage, index: String) -> T? where T: IPersistenceModel {
        return context?.get(objectType, storage: storage, index: index)
    }

    public func get<T>(arrayOf objectType: T.Type, storage: LocalSupportedStorage) -> [T] where T: IPersistenceModel {
        return context?.get(arrayOf: objectType, storage: storage) ?? []
    }

    public func save<T>(_ object: inout T, storage: LocalSupportedStorage) throws where T: IPersistenceModel {
        try context?.save(&object, storage: storage)
    }

    public func delete<T>(_ object: T, storage: LocalSupportedStorage) throws where T: IPersistenceModel {
        try context?.delete(object, storage: storage)
    }

    public func delete<T>(by objectType: T.Type, storage: LocalSupportedStorage) throws where T: IPersistenceModel {
        try context?.delete(by: objectType, storage: storage)
    }

    public func deleteAllObjects(in storage: [LocalSupportedStorage]) throws {
        try context?.deleteAllObjects(in: storage)
    }
}
