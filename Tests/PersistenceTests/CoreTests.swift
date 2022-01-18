import Foundation
import XCTest

@testable import Persistence

class CoreTests: XCTestCase {
    
    func generateSUT() -> IPersistence {
        return Persistence()
    }
}

final class TestObject: IPersistenceModel {
    var retainOriginalIndex: Bool = false
    var index: String?
    
    convenience init(index: String) {
        self.init()
        self.index = index
    }
    
    var name = "name"
}
