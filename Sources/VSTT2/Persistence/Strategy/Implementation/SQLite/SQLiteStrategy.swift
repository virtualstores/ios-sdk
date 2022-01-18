import Foundation
import SQLite

final class SQLiteStrategy: ILocalStrategy {

    let genericSQLiteObject = Table(Constant.tableName)
    let index = Expression<String>(Constant.indexKey)
    let className = Expression<String>(Constant.classNameKey)
    let jsonObject = Expression<String>(Constant.jsonObjectKey)
    let updatedAt = Expression<Date>(Constant.updateAtKey)

    init() {
        do {
            try createTable()
            try createIndex()
        } catch { }
    }

    private func createTable() throws {
        guard let db = SQLiteDataStore.sharedInstance.database else {
            throw StorageContextError.datastoreConnectionError
        }
        do {
            _ = try db.run( genericSQLiteObject.create(ifNotExists: true) { table in
                table.column(index, primaryKey: true)
                table.column(className)
                table.column(jsonObject)
                table.column(updatedAt)
            })

        } catch { }
    }

    private func createIndex() throws {
        guard let db = SQLiteDataStore.sharedInstance.database else {
            throw StorageContextError.datastoreConnectionError
        }

        try db.run(genericSQLiteObject.createIndex(className))
    }

    func get<T>(_ objectType: T.Type, index objectIndex: String) -> T? where T: IPersistenceModel {
        guard let db = SQLiteDataStore.sharedInstance.database else {
            return nil
        }

        let targetClassName = String(describing: T.self)

        do {
            let query = genericSQLiteObject.filter(index == objectIndex && className == targetClassName)
            let items = try db.prepare(query)
            for item in  items {
                let obj = try T.fromJSON(item[jsonObject])
                return obj
            }

        } catch { }

        return nil
    }

    func get<T>(_ objectType: T.Type) -> T? where T: IPersistenceModel {
        return get(arrayOf: objectType).first
    }

    func get<T>(arrayOf objectType: T.Type) -> [T] where T: IPersistenceModel {
        guard let db = SQLiteDataStore.sharedInstance.database else {
            return []
        }

        var retArray = [T]()
        let targetClassName = String(describing: T.self)

        do {
            let query = genericSQLiteObject.filter(className == targetClassName)
            let items = try db.prepare(query)
            for item in  items {
                let obj = try T.fromJSON(item[jsonObject])
                retArray.append(obj)
            }

        } catch { }

        return retArray
    }

    func save<T>(_ object: inout T) throws where T: IPersistenceModel {
        guard let db = SQLiteDataStore.sharedInstance.database else {
            throw StorageContextError.datastoreConnectionError
        }

        let newClassName = String(describing: T.self)

        guard get(arrayOf: type(of: object)).filter({ $0.index == object.index }).count == 0 else {
            return try update(object)
        }

        let newIndex = generateUniqueID(
            currentIndex: object.index,
            retainOriginalIndex: object.retainOriginalIndex
        )

        object.index = newIndex
        object.retainOriginalIndex = true

        do {
            let parsedJsonObject = try object.toJSON()

            let insert = genericSQLiteObject.insert(index <- newIndex,
                                                    className <- newClassName,
                                                    jsonObject <- parsedJsonObject,
                                                    updatedAt <- Date())
            try db.run(insert)
        } catch let error {
            throw PersistenceModelError.couldNotBeEncoded(error)
        }
    }

    private func update<T>(_ object: T) throws where T: IPersistenceModel {
        guard let db = SQLiteDataStore.sharedInstance.database else {
            throw StorageContextError.datastoreConnectionError
        }

        if let id = object.index {
            let query = genericSQLiteObject.filter(index == id)
            do {
                let parsedJsonObject = try object.toJSON()
                let updateObject = query.update(self.jsonObject <- parsedJsonObject)
                try db.run(updateObject)
            } catch let error {
                throw StorageContextError.objectCouldNotBeSaved(error)
            }
        }
    }

    func delete<T>(_ object: T) throws where T: IPersistenceModel {
        guard let db = SQLiteDataStore.sharedInstance.database else {
            throw StorageContextError.datastoreConnectionError
        }

        if let id = object.index {
            let query = genericSQLiteObject.filter(index == id)
            do {
                let tmp = try db.run(query.delete())
                guard tmp == 1 else {
                    throw StorageContextError.unknowDeleteError
                }
            } catch let error {
                throw StorageContextError.objectCouldNotBeDeleted(error)
            }
        }
    }

    func delete<T>(by objectType: T.Type) throws where T: IPersistenceModel {
        guard let db = SQLiteDataStore.sharedInstance.database else {
            throw StorageContextError.datastoreConnectionError
        }

        let newClassName = String(describing: T.self)

        let query = genericSQLiteObject.filter(className == newClassName)
        do {
            try db.run(query.delete())
        } catch let error {
            throw StorageContextError.objectCouldNotBeDeleted(error)
        }
    }

    func deleteAllObjects() throws {
        guard let db = SQLiteDataStore.sharedInstance.database else {
            throw StorageContextError.datastoreConnectionError
        }

        let query = genericSQLiteObject.delete()
        do {
            try db.run(query)
        } catch let error {
            throw StorageContextError.objectCouldNotBeDeleted(error)
        }
    }
}
