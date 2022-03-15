import Foundation

enum PersistenceModelError: Error {
    case dataCorrupted
    case couldNotBeEncoded(Error)
    case couldNotBeDecoded(Error)
}

enum StorageContextError: Error {
    case objectCouldNotBeSaved(Error)
    case objectCouldNotBeDeleted(Error)
    case unknowDeleteError
    case datastoreConnectionError
}
