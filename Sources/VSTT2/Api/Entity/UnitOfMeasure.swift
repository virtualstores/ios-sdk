//
// UnitOfMeasure
// VSTT2
//
// Created by Hripsime on 2022-01-19
// Copyright Virtual Stores - 2022

import Foundation

public enum UnitOfMeasure: String, Codable {
    case each = "EACH"
    case kilogram = "KILOGRAM"
    case gram = "GRAM"
    case ounce = "OUNCE"
    case pound = "POUND"
    case squareMeter = "SQUARE_METER"
    case squareCentimeter = "SQUARE_CENTIMETER"
    case squareMillimeter = "SQUARE_MILLIMETER"
    case squareInch = "SQUARE_INCH"
    case squareFoot = "SQUARE_FOOT"
    case squareYard = "SQUARE_YARD"
    case meter = "METER"
    case centimeter = "CENTIMETER"
    case millimeter = "MILLIMETER"
    case inch = "INCH"
    case foot = "FOOT"
    case yard = "YARD"
    case cubicMeter = "CUBIC_METER"
    case liter = "LITER"
    case cubicCentimeter = "CUBIC_CENTIMETER"
    case cubicInch = "CUBIC_INC"
    case cubicFoot = "CUBIC_FOOT"
    case cubicYard = "CUBIC_YARD"

    public var localizedShortDescription: String {
        switch self {
        case .each:
            return "st"
        case .kilogram:
            return "kg"
        case .gram:
            return "g"
        case .ounce:
            return "oz"
        case .pound:
            return "lbs"
        case .squareMeter:
            return "m2"
        case .squareCentimeter:
            return "cm2"
        case .squareMillimeter:
            return "mm2"
        case .squareInch:
            return "in2"
        case .squareFoot:
            return "ft2"
        case .squareYard:
            return "yd2"
        case .meter:
            return "m"
        case .centimeter:
            return "cm"
        case .millimeter:
            return "mm"
        case .inch:
            return "in"
        case .foot:
            return "ft"
        case .yard:
            return "yd"
        case .cubicMeter:
            return "m3"
        case .liter:
            return "l"
        case .cubicCentimeter:
            return "cm3"
        case .cubicInch:
            return "in3"
        case .cubicFoot:
            return "ft3"
        case .cubicYard:
            return "yd3"
        }
    }

    public init(fromLocalizedString str: String) {
        switch str {
        case "st":
            self = .each
        case "kg":
            self = .kilogram
        case "g":
            self = .gram
        case "oz":
            self = .ounce
        case "lbs":
            self = .pound
        case "m2":
            self = .squareMeter
        case "cm2":
            self = .squareCentimeter
        case "mm2":
            self = .squareMillimeter
        case "in2":
            self = .squareInch
        case "ft2":
            self = .squareFoot
        case "yd2":
            self = .squareYard
        case "m":
            self = .meter
        case "cm":
            self = .centimeter
        case "mm":
            self = .millimeter
        case "in":
            self = .inch
        case "ft":
            self = .foot
        case "yd":
            self = .yard
        case "m3":
            self = .cubicMeter
        case "l":
            self = .liter
        case "cm3":
            self = .cubicCentimeter
        case "in3":
            self = .cubicInch
        case "ft3":
            self = .cubicFoot
        case "yd3":
            self = .cubicYard
        default:
            self = .each
        }
    }
}

public struct CartItemQuantity: Codable {

    public let deliveredNow: Double?
    public let quantity: Double?
    public let unitOfMeasure: UnitOfMeasure?
    public let updateAllowed: Bool?

    public init(deliveredNow: Double?, quantity: Double?, unitOfMeasure: UnitOfMeasure?, updateAllowed: Bool?) {
        self.deliveredNow = deliveredNow
        self.quantity = quantity
        self.unitOfMeasure = unitOfMeasure
        self.updateAllowed = updateAllowed
    }
}
