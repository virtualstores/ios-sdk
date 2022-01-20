//
// CreateVisitResponseTests
// VSTT2
//
// Created by Hripsime on 2022-01-20
// Copyright Virtual Stores - 2022

import XCTest
@testable import VSEngineWrapper
import VSTT2

extension String {
    static var createVisitResponseFixture: String {
        """
        {
            "visitId": 1
        }
        """
    }
}

final class CreateVisitResponseTests: XCTestCase {
    func test_encodinge_valide_data() {
        guard let jsonData = String.createVisitResponseFixture.data(using: .utf8), let createVisitResponse: CreateVisitResponse = try? JSONDecoder().decode(CreateVisitResponse.self, from: jsonData) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(createVisitResponse.visitId, 1)
    }
}
