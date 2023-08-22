//
//  MLInterfaceVersionsService.swift
//  
//
//  Created by Théodore Roos on 2023-04-11.
//

import Foundation
import Combine

final class MLInterfaceVersionsService: DataFetchingManager {
  func call(with parameters: MLInterfaceVersionsParameters) -> AnyPublisher<MLInterfaceVersions, Error> {
    execute(parameters, errorType: Error.self)
  }
}

struct MLInterfaceVersions: Codable {
  let interfaces: [String: Interface]

  func print() {
    interfaces.forEach { (key, value) in
      Swift.print("Interface", key)
      Swift.print("    MLInterfaceVersion", value.mlInterfaceVersion)
      Swift.print("    iOS")
      Swift.print("        LatestVersion", value.iOS.latestVersion)
      Swift.print("        Versions")
      value.iOS.versions.forEach { (key, value) in
        Swift.print("            Key", key)
        Swift.print("                ModelVerion", value.modelVersion)
        Swift.print("                ID         ", value.id)
        Swift.print("                ModelURL   ", value.modelUrl)
        Swift.print("                Name       ", value.name)
        Swift.print("                Deprecated ", value.deprecated)
      }
    }
  }

  struct Interface: Codable {
    let mlInterfaceVersion: String
    let iOS: Device

    struct Device: Codable {
      let latestVersion: String
      let versions: [String: Version]

      struct Version: Codable {
        let modelVersion: String
        let id: String
        let modelUrl: String
        let name: String
        let deprecated: Bool
        let frameSize: Int32
        let smoothing: Bool
      }
    }
  }
}
