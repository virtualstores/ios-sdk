//
//  ApiKeyRepository.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-01-30.
//

import Foundation

protocol IApiKeyRepository {
  func clearAllApiKeys()
  func get(for type: RoutingType) -> String?
  func set(for type: RoutingType, value: String)
}

class ApiKeyRepository {
  private var centralServerApiKey: String?
  private var dataServerApiKey: String?
  private var mlModelServerApiKey: String? = "kanelbulle"
}

extension ApiKeyRepository: IApiKeyRepository {
  func clearAllApiKeys() {
    centralServerApiKey = nil
    dataServerApiKey = nil
    mlModelServerApiKey = nil
  }

  func get(for type: RoutingType) -> String? {
    switch type {
    case .analytics: return dataServerApiKey
    case .central: return centralServerApiKey
    case .ml: return mlModelServerApiKey
    case .unknown: return nil
    }
  }

  func set(for type: RoutingType, value: String) {
    switch type {
    case .analytics: dataServerApiKey = value
    case .central: centralServerApiKey = value
    case .ml: mlModelServerApiKey = value
    case .unknown: break
    }
  }
}
