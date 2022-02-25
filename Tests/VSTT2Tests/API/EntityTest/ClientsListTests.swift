//
// ClientsListTests
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import XCTest
//@testable import VSEngineWrapper
import VSTT2

extension String {
    static var clientFixture: String {
        """
        {
            "id": 1,
            "name": "Gunnis Hp"
        }
        """
    }
}

final class ClientsListTests: XCTestCase {
    func test_encodinge_valide_data() {
        guard let jsonData = String.clientFixture.data(using: .utf8), let client: Client = try? JSONDecoder().decode(Client.self, from: jsonData) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(client.clientId, "1")
        XCTAssertEqual(client.name, "Gunnis Hp")
    }
}
