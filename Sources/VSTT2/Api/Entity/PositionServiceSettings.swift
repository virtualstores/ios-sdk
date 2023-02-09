//
//  PositionServiceSettings.swift
//  
//
//  Created by Théodore Roos on 2022-11-29.
//

import Foundation

public struct PositionServiceSettings: Codable {
  public let useML: Bool
  public let useCoefficientOptimizer: Bool
  public let useDriftCompensator: Bool
  public let boolValues: [String: Bool]?
  public let stringValues: [String: String]?
  public let stringArrayValues: [String: [String]]?
  public let intValues: [String: Int]?
  public let intArrayValues: [String: [Int]]?
  public let floatValues: [String: Double]?
  public let floatArrayValues: [String: [Double]]?
}
