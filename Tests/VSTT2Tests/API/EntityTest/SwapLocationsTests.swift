//
// SwapLocationsTests
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import XCTest
//@testable import VSEngineWrapper
import VSTT2

extension String {
    static var swapLocationsFixture: String {
        """
          {
            "id": 1,
            "rtlsOptionsId": 18,
            "name": "portal stair to beijer",
            "point": {
              "name": "point name",
              "angle": 90,
              "coordinate": [5.055941944021356, 3.3961912680936734]
            },
            "paths": [
              {
                "swapLocationToId": 2,
                "heightDiffInMeters": 0.0,
                "direction": 2,
                "type": 2
              }
            ],
            "coordinates": [
                [5.773387062065467, 3.308376817594194],
                [7.110863622944521, 1.9792873938607158],
                [6.827277307634176, 0.25159958514848313],
                [4.276409342551233, 0.24129893816478898],
                [4.335986252343673, 3.309230362759763]
            ]
          }
        """
    }
}

final class SwapLocationsTests: XCTestCase {
    func test_encodinge_valide_data() {
        guard let jsonData = String.swapLocationsFixture.data(using: .utf8), let swapLocation: SwapLocation = try? JSONDecoder().decode(SwapLocation.self, from: jsonData) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(swapLocation.id, 1)
        XCTAssertEqual(swapLocation.rtlsOptionsId, 18)
        XCTAssertEqual(swapLocation.name, "portal stair to beijer")
        XCTAssertEqual(swapLocation.point.name, "point name")
        XCTAssertEqual(swapLocation.point.angle, 90.0)
        XCTAssertEqual(swapLocation.coordinates.first?.x, 5.773387062065467)
        XCTAssertEqual(swapLocation.coordinates.first?.y, 3.308376817594194)
        XCTAssertEqual(swapLocation.paths.first?.swapLocationToId, 2)
        XCTAssertEqual(swapLocation.paths.first?.heightDiffInMeters, 0.0)
        XCTAssertEqual(swapLocation.paths.first?.direction.rawValue, 2)
        XCTAssertEqual(swapLocation.paths.first?.type.rawValue, 2)
    }
}
