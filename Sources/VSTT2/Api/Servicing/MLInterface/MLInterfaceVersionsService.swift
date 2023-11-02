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

  func printInterfaces() {
    interfaces.sorted(by: { $0.key < $1.key }).forEach { (key, value) in
      print("Interface", key)
      print("    MLInterfaceVersion", value.mlInterfaceVersion)
      print("    iOS")
      print("        LatestVersion", value.iOS.latestVersion)
      print("        Versions")
      value.iOS.versions.forEach { (key, value) in
        print("            Key", key)
        print("                ModelVerion         ", value.modelVersion)
        print("                ID                  ", value.id)
        print("                ModelURL            ", value.modelUrl)
        print("                Name                ", value.name)
        print("                Deprecated          ", value.deprecated)
        print("                FrameSize           ", value.frameSize)
        print("                Smoothing           ", value.smoothing)
        print("                FeatureSequence     ", value.featureSequence)
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
        let featureSequence: [String]
      }
    }
  }
}
