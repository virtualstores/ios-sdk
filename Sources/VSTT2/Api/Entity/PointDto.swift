//
// PointDto
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation

public struct PointDto: Codable {
    public var positionInList: Int?
    public var x: Double?
    public var y: Double?

    public init(positionInList: Int?, x: Double?, y: Double?) {
        self.positionInList = positionInList
        self.x = x
        self.y = y
    }
}
