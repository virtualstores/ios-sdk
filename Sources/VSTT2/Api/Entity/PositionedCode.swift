//
// PositionedCode
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics

public struct PositionedCode: Codable, Equatable {
    let code: String
    let xPosition: CGFloat
    let yPosition: CGFloat
    let direction: Double
    let type: CodeType

    public enum CodeType: Int, Codable {
        case start = 0
        case stop = 1
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case xPosition = "x"
        case yPosition = "y"
        case direction
        case type
    }

    public init(code: String, xPosition: CGFloat, yPosition: CGFloat, direction: Double, type: CodeType) {
        self.code = code
        self.xPosition = xPosition
        self.yPosition = yPosition
        self.direction = direction
        self.type = type
    }
}
