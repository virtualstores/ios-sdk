//
//  SyncFilter.swift
//  
//
//  Created by Théodore Roos on 2022-11-29.
//

import Foundation

public struct SyncFilter: Codable {
  public let isEnabled: Bool
  public let syncDistanceInMetersThreshold: Double
  public let numberOfRescueModesThreshold: Int
}
