//
// PointF
// VSTT2
//
// Created by Hripsime on 2021-12-17
// Copyright Virtual Stores - 2021

import Foundation

public struct PointF: Codable {
    public let x: Float
    public let y: Float
    
    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    public enum CodingKeys: String, CodingKey {
        case x
        case y
    }
}
