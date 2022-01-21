import Foundation

// swiftlint:disable implicit_getter

final class StrategyContext {
    private var contexts = [AnyHashable: Any]()

    init() {
        LocalSupportedStorage.allCases.forEach { storage in
            contexts[storage] = storage.persistence
        }
    }
}

extension StrategyContext: ILocalContext {
    func get<T>(_ objectType: T.Type, storage: LocalSupportedStorage) -> T? where T: IPersistenceModel {
        return (contexts[storage] as? ILocalStrategy)?.get(objectType)
    }

    func get<T>(_ objectType: T.Type, storage: LocalSupportedStorage, index: String) -> T? where T: IPersistenceModel {
        return (contexts[storage] as? ILocalStrategy)?.get(objectType, index: index)
    }

    func get<T>(arrayOf objectType: T.Type, storage: LocalSupportedStorage) -> [T] where T: IPersistenceModel {
        return (contexts[storage] as? ILocalStrategy)?.get(arrayOf: objectType) ?? []
    }

    func save<T>(_ object: inout T, storage: LocalSupportedStorage) throws where T: IPersistenceModel {
        try (contexts[storage] as? ILocalStrategy)?.save(&object)
    }

    func delete<T>(_ object: T, storage: LocalSupportedStorage) throws where T: IPersistenceModel {
        try (contexts[storage] as? ILocalStrategy)?.delete(object)
    }

    func delete<T>(by objectType: T.Type, storage: LocalSupportedStorage) throws where T: IPersistenceModel {
        try (contexts[storage] as? ILocalStrategy)?.delete(by: objectType)
    }

    func deleteAllObjects(in storage: [LocalSupportedStorage]) throws {
        for strategy in contexts.values {
            try (strategy as? ILocalStrategy)?.deleteAllObjects()
        }
    }
}
