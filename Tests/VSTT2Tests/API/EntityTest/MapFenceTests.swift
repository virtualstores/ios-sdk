//
// MapFenceTests
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import XCTest
import VSTT2
@testable import VSFoundation

extension String {
    static var mapFenceFixture: String {
        """
        {
        "type": "Multipolygon",
        "properties": {
          "width": 2697.4854,
          "height": 5549.91113
        },
             "coordinates": [[[[ 447.04081 ]]]]
    }
    """
    }
}

final class MapFenceTests: XCTestCase {
    func test_encodinge_valide_data() {
        guard let jsonData = String.mapFenceFixture.data(using: .utf8), let mapFence: MapFence = try? JSONDecoder().decode(MapFence.self, from: jsonData) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(mapFence.type, "Multipolygon")
        XCTAssertEqual(mapFence.properties.height, 5549.91113)
        XCTAssertEqual(mapFence.properties.width, 2697.4854)
        XCTAssertEqual(mapFence.coordinates.first?.first?.first?.first, 447.04081)
    }
}
