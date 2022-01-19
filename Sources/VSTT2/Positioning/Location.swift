//
// TT2Position
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics
import CoreLocation

/// A position in the navigation space in meters and with the origin at the top-left corner.
public struct TT2Position {
    /// The x-value, i.e. how far away from the leftmost corner this position is.
    public var xPosition: Double {
        Double(point.x)
    }

    /// The y-value, i.e. how far away from the topmost corner this position is.
    public var yPosition: Double {
        Double(point.y)
    }

    public let point: CGPoint

    public let offset: CGPoint

    /// Initializes a position with x and y values.
    public init(point: CGPoint, offset: CGPoint) {
        self.point = point
        self.offset = offset
    }

    init(xPosition: Double, yPosition: Double, offset: CGPoint) {
        self.point = CGPoint(x: xPosition, y: yPosition)
        self.offset = offset
    }

    /// The scale of the current navigation space. Is 50 by default.
    /// More specifically, this is the ratio of coordinates to meters. If the scale is 50, that means that 1 degree is 50 meters.
    public static internal(set) var scale: Double = 50.0

    public static var pixelsPerMeterFactor: Double {
        1000.0 / TT2Position.scale
    }

    /// The height of the navigation space. This is used to convert to/from positions with the origin at the bottom-left corner.

    /// This will be set by the MapController, which means it cannot be used before the MapController has been initialized.
    public static internal(set) var navigationSpaceSize: CGSize = .zero

    public static var navigationSpaceHeight: Double {
        Double(TT2Position.navigationSpaceSize.height)
    }

    public static var navigationSpaceWidth: Double {
        Double(TT2Position.navigationSpaceSize.width)
    }

     ///  Converts the position to the unit used by the server.
    public var inServerPixels: CGPoint {
        return CGPoint(x: self.xPosition * TT2Position.scale, y: self.yPosition * TT2Position.scale)
    }

    /// Converts the position to coordinates, which can be used by Mapbox.
    /// This cannot be used until the MapController has been initialized.
    public var inCoordinates: CLLocationCoordinate2D {
        let latitude = yPosition / TT2Position.pixelsPerMeterFactor
        let longitude = xPosition / TT2Position.pixelsPerMeterFactor
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public struct TT2Course {
    /// The course in radians.
    public var radians: Double = 0.0

    /// The course in degrees.
    public var degrees: Double {
        get {
            self.radians * (180.0 / .pi)
        }

        set {
            self.radians = newValue * (.pi / 180.0)
        }
    }

    /// Initializes a course with radians.
    public init(fromRadians radians: Double) {
        self.radians = radians
    }

    /// Initializes a course with degrees.
    public init(fromDegrees degrees: Double) {
        self.degrees = degrees
    }
}

/// A location that contains a position, a course and some values that determine how certain this location is.
public struct TT2Location {
    /// The position in meters, relative to the top-left corner.
    public var position: TT2Position

    /// The course in which this location is pointing towards.
    public var course: TT2Course

    /// How confident we are of this location.
    public var confidence: Double

    /// A radius in which the location is within.
    public var radius: Double

    /// The time in which this location was valid. Can be nil.
    public var timestamp: Date

    /// Direction sync flag
    public var syncDirection: Bool

    /// If this location is a valid sync location. Can be used when synchronizing a position manager.
    public var forceSyncPosition: Bool

    /// Initialize a location.
    public init (position: TT2Position, course: TT2Course, confidence: Double = 1.0,
                 radius: Double = 1.0, timestamp: Date = Date(), syncDirection: Bool = false,
                 forceSyncPosition: Bool = false) {
        self.position = position
        self.course = course
        self.confidence = confidence
        self.radius = radius
        self.timestamp = timestamp
        self.syncDirection = syncDirection
        self.forceSyncPosition  = forceSyncPosition
    }
}
