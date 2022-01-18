import Foundation
import SQLite

final class SQLiteDataStore {
    static let sharedInstance = SQLiteDataStore()
    let database: Connection?

    private init() {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("VSPersistence").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            database = nil
        }
    }
}
