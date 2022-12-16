//
//  UserControllerTests.swift
//  
//
//  Created by Théodore Roos on 2022-12-07.
//

import VSFoundation
import Foundation
import XCTest
@testable import VSTT2

final class UserControllerTests: XCTestCase {
  func test_get_VPS_settings() {
    let business = UserControllerBusiness()
    let settings1 = PositionServiceSettings(useML: true, useCoefficientOptimizer: true, useDriftCompensator: false)

    let expectedResult1 = VPSSettings(mlAlgos: [.coefficientOptimizer], useML: true, mlAlgo: .coefficientOptimizer)
    let result1 = business.getVPSSettings(positionServiceSettings: settings1)
    XCTAssertEqual(result1.mlAlgos, expectedResult1.mlAlgos)
    XCTAssertEqual(result1.useML, expectedResult1.useML)
    XCTAssertEqual(result1.mlAlgo, expectedResult1.mlAlgo)
  }
}
