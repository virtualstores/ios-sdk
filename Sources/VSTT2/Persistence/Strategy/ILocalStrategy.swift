import Foundation

protocol IBaseStrategy { }

extension IBaseStrategy {

    func generateUniqueID(currentIndex: String?, retainOriginalIndex: Bool) -> String {
        if let currentIndex = currentIndex, !currentIndex.isEmpty, retainOriginalIndex {
            return currentIndex
        }

        var uniqueIndex = UUID().uuidString

        if let currentIndex = currentIndex, !currentIndex.isEmpty {
            uniqueIndex = currentIndex
        }

        return uniqueIndex
    }
}

protocol ILocalStrategy: IBaseStrategy {
    func get<T: IPersistenceModel>(_ objectType: T.Type) -> T?
    func get<T: IPersistenceModel>(_ objectType: T.Type, index: String) -> T?
    func get<T: IPersistenceModel>(arrayOf objectType: T.Type) -> [T]
    func save<T: IPersistenceModel>(_ object: inout T) throws
    func delete<T: IPersistenceModel>(_ object: T) throws
    func delete<T: IPersistenceModel>(by objectType: T.Type) throws
    func deleteAllObjects() throws
}

protocol ICloudStrategy: IBaseStrategy {
    func save<T: IPersistenceModel>(_ object: inout T,
                                    complete: @escaping (Result<Bool, Error>) -> Void)

    func get<T: IPersistenceModel>(_ objectType: T.Type,
                                   complete: @escaping (Result<[T], Error>) -> Void)

    func delete<T: IPersistenceModel>(by objectType: T.Type,
                                      complete: @escaping (Result<Bool, Error>) -> Void)

    func update<T: IPersistenceModel>(_ object: inout T,
                                      complete: @escaping (Result<Bool, Error>) -> Void)
}
