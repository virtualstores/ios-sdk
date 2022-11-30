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
}
