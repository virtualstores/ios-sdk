//
// SwapLocation
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics

public class SwapLocation: Codable {
    public class Point: Codable {
        public let name: String?
        public let angle: Double
        public let coordinate: CGPoint

        public init(name: String, angle: Double, coordinate: CGPoint) {
            self.name = name
            self.angle = angle
            self.coordinate = coordinate
        }
    }

    public class Path: Codable {
        public let swapLocationToId: Int64
        public let heightDiffInMeters: Double
        public let direction: Directions
        public let type: Types

        public enum Directions: Int, Codable {
            case none = 0
            case up = 1
            case down = 2
            case upAndDown = 3
        }

        public enum Types: Int, Codable {
            case none = 0
            case elevator = 1
            case stairs = 2
            case escalator = 3
            case door = 4
        }

        public init(swapLocationToId: Int64, heightDiffInMeters: Double, direction: Directions, type: Types) {
            self.swapLocationToId = swapLocationToId
            self.heightDiffInMeters = heightDiffInMeters
            self.direction = direction
            self.type = type
        }
    }

    public let id: Int64
    public let rtlsOptionsId: Int64
    public let name: String
    public let point: Point
    public let paths: [Path]
    public let coordinates: [CGPoint]

    public init(id: Int64, rtlsOptionsId: Int64, name: String, point: Point, paths: [Path], coordinates: [CGPoint]) {
        self.id = id
        self.rtlsOptionsId = rtlsOptionsId
        self.name = name
        self.point = point
        self.paths = paths
        self.coordinates = coordinates
    }
}
