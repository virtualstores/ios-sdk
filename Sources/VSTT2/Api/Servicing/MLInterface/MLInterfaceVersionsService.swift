//
//  MLInterfaceVersionsService.swift
//
//
//  Created by Théodore Roos on 2023-04-11.
//

import Foundation
import Combine
import VSFoundation

final class MLInterfaceVersionsService: DataFetchingManager {
  func call(with parameters: MLInterfaceVersionsParameters) -> AnyPublisher<MLInterfaceVersions, Error> {
    execute(parameters, errorType: Error.self)
  }
}

struct MLInterfaceVersions: Codable {
  let mlCatalog: MLCatalog

  func logMLCatalog() {
    log(padding: 0, tag: "MLCatalog", description: "")
    mlCatalog.targets.sorted(by: { $0.key < $1.key }).forEach { (key, value) in
      log(padding: 1, tag: "Target", description: key)
      log(padding: 2, tag: "LatestMLVersion", description: value.ios.latestMLVersion.description)
      log(padding: 2, tag: "MLVersionFilter", description: value.ios.mlVersionFilter.description)
      log(padding: 2, tag: "LatestNLVersion", description: value.ios.latestNLVersion.description)
      log(padding: 2, tag: "NLVersionFilter", description: value.ios.nlVersionFilter.description)
    }
    log(padding: 1, tag: "iOS", description: "")
    mlCatalog.ios.mlModels.sorted(by: { $0.key < $1.key }).forEach { (key, value) in
      log(padding: 2, tag: "MLModel", description: key)
      log(padding: 3, tag: "Version", description:  value.version.description)
      log(padding: 3, tag: "IsDeprecated", description: value.isDeprecated.description)
      log(padding: 3, tag: "ID", description: value.id)
      log(padding: 3, tag: "ModelUrl", description: value.modelUrl)
      log(padding: 3, tag: "Name", description: value.name)
      log(padding: 3, tag: "FrameSize", description: value.frameSize.description)
      log(padding: 3, tag: "Smoothing", description: value.smoothing.description)
      log(padding: 3, tag: "FeatureSequence", description: value.featureSequence.description)
    }
    mlCatalog.ios.nlModels.sorted(by: { $0.key < $1.key }).forEach { (key, value) in
      log(padding: 2, tag: "NLModel", description: key)
      log(padding: 3, tag: "Version", description: value.version.description)
      log(padding: 3, tag: "IsDeprecated", description: value.isDeprecated.description)
      log(padding: 3, tag: "ID", description: value.id)
      log(padding: 3, tag: "ModelUrl", description: value.modelUrl)
      log(padding: 3, tag: "Name", description: value.name)
    }
  }

  private func log(padding amountOfPadding: Int, tag: String, description: String) {
    var padding = ""
    (0..<amountOfPadding).forEach { (_) in padding = padding + "    " }
    print(padding, tag, description)
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

  struct MLCatalog: Codable {
    let targets: [String: Target]
    let ios: Device

    enum ModelTypeEnum {
      case ml, nl, np
    }

    struct Target: Codable {
      let ios: Device

      struct Device: Codable {
        let useML: Bool
        let useNL: Bool
        let useMC: Bool
        let useNP: Bool
        let latestMLVersion: Int
        let mlVersionFilter: [Int]
        let latestNLVersion: Int
        let nlVersionFilter: [Int]
        let latestNPVersion: Int
        let npVersionFilter: [Int]

        private enum CodingKeys: String, CodingKey {
          case useML,
          useNL,
          useMC,
          useNP,
          latestMLVersion,
          mlVersionFilter,
          latestNLVersion,
          nlVersionFilter,
          latestNPVersion,
          npVersionFilter
        }

        init(from decoder: Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          useML = try container.decodeIfPresent(Bool.self, forKey: .useML) ?? true
          useNL = try container.decodeIfPresent(Bool.self, forKey: .useNL) ?? false
          useMC = try container.decodeIfPresent(Bool.self, forKey: .useMC) ?? false
          useNP = try container.decodeIfPresent(Bool.self, forKey: .useNP) ?? false
          latestMLVersion = try container.decodeIfPresent(Int.self, forKey: .latestMLVersion) ?? 1
          mlVersionFilter = try container.decodeIfPresent([Int].self, forKey: .mlVersionFilter) ?? []
          latestNLVersion = try container.decodeIfPresent(Int.self, forKey: .latestNLVersion) ?? 1
          nlVersionFilter = try container.decodeIfPresent([Int].self, forKey: .nlVersionFilter) ?? []
          latestNPVersion = try container.decodeIfPresent(Int.self, forKey: .latestNPVersion) ?? 1
          npVersionFilter = try container.decodeIfPresent([Int].self, forKey: .npVersionFilter) ?? []
        }
      }
    }

    struct Device: Codable {
      let mlModels: [String: MLVersion]
      let nlModels: [String: NLVersion]
      let npModels: [String: NPVersion]

      struct MLVersion: Codable {
        let version: Int
        let isDeprecated: Bool
        let id: String
        let minimumSupportedVPSVersion: String
        let minimumSupportedSDKVersion: String
        let modelUrl: String
        let name: String
        let frameSize: Int32
        let smoothing: Bool
        let featureSequence: [String]
        let stepNumberInput: Bool
      }

      struct NLVersion: Codable {
        let version: Int
        let minimumSupportedVPSVersion: String
        let minimumSupportedSDKVersion: String
        let isDeprecated: Bool
        let id: String
        let modelUrl: String
        let name: String
        let resolution: Double
      }

      struct NPVersion: Codable {
        let version: Int
        let minimumSupportedVPSVersion: String
        let minimumSupportedSDKVersion: String
        let isDeprecated: Bool
        let id: String
        let modelUrl: String
        let name: String
      }
    }
  }
}

extension MLInterfaceVersions.MLCatalog {
  func getLatestSupportedModel(
    _ type: ModelTypeEnum,
    params: TT2Settings.TT2ModelParams,
    sdkVersion: String,
    vpsVersion: String
  ) -> (any DeviceVersioning)? {
    guard let target = targets[params.target.description]?.ios else { return nil }
    let models: [String: DeviceVersioning]
    let filter: [Int]
    switch type {
    case .ml:
      guard target.useML else { return nil }
      models = ios.mlModels
      filter = target.mlVersionFilter
    case .nl:
      guard target.useNL else { return nil }
      models = ios.nlModels
      filter = target.nlVersionFilter
    case .np:
      guard target.useNP else { return nil }
      models = ios.npModels
      filter = target.npVersionFilter
    }

    return models.pick(
      requestedVersion: params.targetMLModelVersion ?? target.latestMLVersion,
      filter: filter,
      sdkVersion: sdkVersion,
      vpsVersion: vpsVersion
    )
  }
}

protocol DeviceVersioning {
  var version: Int { get }
  var minimumSupportedSDKVersion: String { get }
  var minimumSupportedVPSVersion: String { get }
  var isDeprecated: Bool { get }
}

extension MLInterfaceVersions.MLCatalog.Device.MLVersion: DeviceVersioning {}
extension MLInterfaceVersions.MLCatalog.Device.NLVersion: DeviceVersioning {}
extension MLInterfaceVersions.MLCatalog.Device.NPVersion: DeviceVersioning {}

extension Dictionary where Key == String, Value == any DeviceVersioning {
  func pick(
    requestedVersion: Int,
    filter: [Int],
    sdkVersion: String,
    vpsVersion: String
  ) -> DeviceVersioning? {
    let supported = filterAvailableModels(filter: filter)
      .filterSupported(sdkVersion: sdkVersion)
      .filterSupported(vpsVersion: vpsVersion)
      .filter { !$0.value.isDeprecated && $0.value.version <= requestedVersion }
      .map(\.value)
      .sorted { $0.version > $1.version }
    return supported.first(where: { $0.version == requestedVersion }) ?? supported.first
  }

  func filterAvailableModels(filter: [Int]) -> Self {
    self.filter { filter.isEmpty ? true : filter.contains($0.value.version) }
  }

  func filterSupported(sdkVersion: String) -> Self {
    guard let sdkVersion = sdkVersion.asVersion else { return self }
    return filter {
      if let version = $0.value.minimumSupportedSDKVersion.asVersion {
        return sdkVersion >= version
      }
      return true
    }
  }

  func filterSupported(vpsVersion: String) -> Self {
    guard let vpsVersion = vpsVersion.asVersion else { return self }
    return filter {
      if let version = $0.value.minimumSupportedVPSVersion.asVersion {
        return vpsVersion >= version
      }
      return true
    }
  }
}

struct Version {
  let major: Int
  let minor: Int
  let patch: Int

  init(major: Int? = nil, minor: Int? = nil, patch: Int? = nil) {
    self.major = major ?? 0
    self.minor = minor ?? 0
    self.patch = patch ?? 0
  }

  func compareTo(other: Version) -> Int {
    if self == other {
      return 0
    }
    if major > other.major {
      return 1
    } else if major == other.major {
      if minor > other.minor {
        return 1
      } else if minor == other.minor {
        if patch > other.patch {
          return 1
        } else {
          return -1
        }
      } else {
        return -1
      }
    } else {
      return -1
    }
  }

  static func == (lhs: Version, rhs: Version) -> Bool {
    lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
  }

  static func > (lhs: Version, rhs: Version) -> Bool {
    lhs.compareTo(other: rhs) > 0
  }

  static func >= (lhs: Version, rhs: Version) -> Bool {
    lhs.compareTo(other: rhs) >= 0
  }

  static func < (lhs: Version, rhs: Version) -> Bool {
    lhs.compareTo(other: rhs) < 0
  }
}

private extension String {
  var asVersion: Version? {
    let split = clean.split(separator: ".").map({ Int($0) })
    var version: Version?
    if split.count == 3 {
      version = .init(major: split[0], minor: split[1], patch: split[2])
    } else if split.count == 2 {
      version = .init(major: split[0], minor: split[1])
    } else if split.count == 1 {
      version = .init(major: split[0])
    }
    return version
  }

  var clean: String {
    if let range = range(of: "-") {
      let version = String(self[..<range.lowerBound])
      return version
    }
    return self
  }
}
