import XCTest
@testable import Persistence

final class PersistenceTests: CoreTests {
    func test_save_one_object_data() {
        let persistance = generateSUT()
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        
        var object = TestObject()
        
        XCTAssertNoThrow(try persistance.save(&object), "Object are not saved correctly")
    }
    
    func test_save_array_of_objects() {
        let persistance = generateSUT()
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        
        let objects = [TestObject(), TestObject(), TestObject(), TestObject()]
        
        for var object in objects {
            XCTAssertNoThrow(try persistance.save(&object), "Object are not saved correctly")
        }
    }
    
    func test_get_single_object() {
        let persistance = generateSUT()
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        
        var object = TestObject()
        
        XCTAssertNoThrow(try persistance.save(&object))
        XCTAssertNotNil(persistance.get(TestObject.self), "Object are not saved correctly")
    }
    
    func test_get_single_object_by_index() {
        let persistance = generateSUT()
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        
        let firstObjectIndex = UUID.init().description
        var firstObject = TestObject(index: firstObjectIndex)
        firstObject.retainOriginalIndex = true
        
        let secondObjectIndex = UUID.init().description
        var secondObject = TestObject(index: secondObjectIndex)
        secondObject.retainOriginalIndex = true
        
        XCTAssertNoThrow(try persistance.save(&firstObject))
        let retrievedFirstObject = persistance.get(TestObject.self)
        XCTAssertNotNil(retrievedFirstObject, "Object are not saved correctly")
        
        XCTAssertNoThrow(try persistance.save(&secondObject))
        let retrievedSecondObject = persistance.get(TestObject.self, index: secondObjectIndex)
        XCTAssertNotNil(retrievedSecondObject, "Object are not saved correctly")
        XCTAssertEqual(retrievedSecondObject?.index, secondObjectIndex)
    }
    
    func test_get_array_of_objects() {
        let persistance = generateSUT()
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        
        let objects = [TestObject(), TestObject(), TestObject(), TestObject()]
        
        for var object in objects {
            XCTAssertNoThrow(try persistance.save(&object))
        }
      
        XCTAssert(persistance.get(arrayOf: TestObject.self).count == objects.count, "Not all object was saved")
    }
    
    func test_remove_single_object() {
        let persistance = generateSUT()
        
        var object = TestObject()
        
        XCTAssertNoThrow(try persistance.save(&object), "Object are not saved correctly")
        XCTAssertNoThrow(try persistance.delete(object))
        
        XCTAssertNil(persistance.get(TestObject.self))
    }
    
    func test_remove_single_object_when_exist_more() {
        let persistance = generateSUT()
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        
        var object = TestObject()
        var object2 = TestObject()
        
        XCTAssertNoThrow(try persistance.save(&object), "Object are not saved correctly")
        XCTAssertNoThrow(try persistance.save(&object2), "Object are not saved correctly")
        XCTAssertNoThrow(try persistance.delete(object))
        
        XCTAssertNotNil(persistance.get(TestObject.self))
    }
    
    func test_remove_all_object_one_type() {
        let persistance = generateSUT()
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        
        let objects = [TestObject(), TestObject(), TestObject(), TestObject()]
        
        for var object in objects {
            XCTAssertNoThrow(try persistance.save(&object), "Object are not saved correctly")
        }
        
        XCTAssertNoThrow(try persistance.delete(by: TestObject.self))
        XCTAssertNil(persistance.get(TestObject.self))
    }
    
    func test_remove_all_data() {
        let persistance = generateSUT()
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        
        let objects = [TestObject(), TestObject(), TestObject(), TestObject()]
        
        for var object in objects {
            XCTAssertNoThrow(try persistance.save(&object), "Object are not saved correctly")
        }
        
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        XCTAssertNil(persistance.get(TestObject.self))
    }
    
    func test_update_data() {
        let testText = "Test"
        let persistance = generateSUT()
        XCTAssertNoThrow(try persistance.deleteAllObjects())
        
        var object = TestObject()
        
        XCTAssertNoThrow(try persistance.save(&object), "Object are not saved correctly")
        XCTAssertNotNil(persistance.get(TestObject.self))
        object.name = testText
        
        XCTAssertNoThrow(try persistance.save(&object), "Update object are not saved correctly")
        let returnObject = persistance.get(TestObject.self)
        XCTAssertEqual(returnObject?.name, testText, "Object was not updated correctly")
    }
    
    static var allTests = [
        ("test_save_one_object_data", test_save_one_object_data),
        ("test_save_array_of_objects", test_save_array_of_objects),
        ("test_get_single_object", test_get_single_object),
        ("test_get_array_of_objects", test_get_array_of_objects),
        ("test_remove_single_object", test_remove_single_object),
        ("test_remove_all_object_one_type", test_remove_all_object_one_type),
        ("test_remove_all_data", test_remove_all_data),
        ("test_update_data", test_update_data),
    ]
}
