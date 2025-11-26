//
//  MLRepository.swift
//
//
//  Created by Théodore Roos on 2024-05-30.
//

import Combine
import CoreML
import Foundation
import VSFoundation
import ZIPFoundation
import vps

protocol IMLRepository: Disposable {
  func compileModel(type: MLRepository.ModelTypeEnum) -> AnyPublisher<Void, Error>
  func fetchMLInterfaceVersions() -> AnyPublisher<Void, Error>
  func fetchModel(url: URL, id: String, type: MLRepository.ModelTypeEnum) -> AnyPublisher<Void, Error>
  func getMLCatalog() -> MLInterfaceVersions.MLCatalog?
  func getMLModel() -> MLModel?
  func getMLVersion() -> MLInterfaceVersions.MLCatalog.Device.MLVersion?
  func getNLModel() -> MLModel?
  func getNLVersion() -> MLInterfaceVersions.MLCatalog.Device.NLVersion?
  func getVPSMLModelParams() -> VPSMLModelParams?
  func getVPSNLModelParams() -> VPSNLModelParams?
  func load(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion) -> AnyPublisher<Void, Error>
  func load(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion) -> AnyPublisher<Void, Error>
  func set(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion)
  func set(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion)
}

class MLRepository {
  private let tag = "MLRepository"
  private let api: IMLApi = MLApi()
  private var catalog: MLInterfaceVersions.MLCatalog?
  private var currentMLVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion? {
    get {
      guard let data = UserDefaults.standard.value(forKey: "TT2CURRENTMLCATALOGMLVERSION") as? Data else { return nil }
      return try? JSONDecoder().decode(MLInterfaceVersions.MLCatalog.Device.MLVersion.self, from: data)
    }
    set {
      guard let encoded = try? JSONEncoder().encode(newValue) else { return }
      UserDefaults.standard.setValue(encoded, forKey: "TT2CURRENTMLCATALOGMLVERSION")
    }
  }
  private var currentNLVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion? {
    get {
      guard let data = UserDefaults.standard.value(forKey: "TT2CURRENTMLCATALOGNLVERSION") as? Data else { return nil }
      return try? JSONDecoder().decode(MLInterfaceVersions.MLCatalog.Device.NLVersion.self, from: data)
    }
    set {
      guard let encoded = try? JSONEncoder().encode(newValue) else { return }
      UserDefaults.standard.setValue(encoded, forKey: "TT2CURRENTMLCATALOGNLVERSION")
    }
  }
  private lazy var mlParams: VPSMLModelParams? = {
    guard let version = currentMLVersion, let sequence = version.featureSequence.convert else { return nil }
    return VPSMLModelParams(frameSize: version.frameSize, useSmooting: version.smoothing, featureSequence: sequence, stepNumberInput: version.stepNumberInput)
  }()
  private lazy var nlParams: VPSNLModelParams? = {
    guard let version = currentNLVersion else { return nil }
    return VPSNLModelParams(resolution: version.resolution)
  }()
  private var mlModel: MLModel?
  private var nlModel: MLModel?
  private var mlModelName = ""
  private var nlModelName = ""
  private var pathDirectory: URL? {
    try? FileManager.default
      .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("CoreMLModels")
  }
  private var pathMLModel: URL? {
    pathDirectory?
      .appendingPathComponent(mlModelName).appendingPathExtension("mlpackage")
  }
  private var pathNLModel: URL? {
    pathDirectory?
      .appendingPathComponent(nlModelName).appendingPathExtension("mlpackage")
  }
  private var pathEncryptedML: URL? { pathDirectory?.appendingPathExtension("ml.encrypted") }
  private var pathEncryptedNL: URL? { pathDirectory?.appendingPathExtension("nl.encrypted") }
  private var cancellables = Set<AnyCancellable>()
  enum ModelTypeEnum {
    case ml, nl
  }

  init() {
    if let path = pathDirectory {
      try? FileManager.default.removeItem(at: path)
    }
  }

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }
}

extension MLRepository: IMLRepository {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    cancellables.removeAll()
    mlModel = nil
    mlParams = nil
    nlModel = nil
    nlParams = nil
  }

  func compileModel(type: ModelTypeEnum) -> AnyPublisher<Void, Error> {
    let path: URL?
    switch type {
    case .ml: path = pathMLModel
    case .nl: path = pathNLModel
    }
    guard let path = path else { return .fail(with: TT2Error.missingData) }
    return compileModel(path: path)
      .tryMap { [weak self] in
        guard let model = self?.buildModel(path: $0) else { throw NSError(domain: "Can't build model", code: 500) } // TODO: Better error
        switch type {
        case .ml: self?.mlModel = model
        case .nl: self?.nlModel = model
        }
        try? FileManager.default.removeItem(at: path)
        try? FileManager.default.removeItem(at: $0)
      }
      .eraseToAnyPublisher()
  }

  func fetchMLInterfaceVersions() -> AnyPublisher<Void, Error> {
    api.fetchMLInterfaceVersions()
      .map { [weak self] in self?.catalog = $0.mlCatalog }
      .eraseToAnyPublisher()
  }

  func fetchModel(url: URL, id: String, type: ModelTypeEnum) -> AnyPublisher<Void, Error> {
    api.fetchModel(url: url)
      .tryMap { [weak self] in try self?.handleModel(id: id, type: type, data: $0) }
      .eraseToAnyPublisher()
  }

  func getMLCatalog() -> MLInterfaceVersions.MLCatalog? {
    catalog
  }

  func getMLModel() -> MLModel? {
    mlModel
  }

  func getMLVersion() -> MLInterfaceVersions.MLCatalog.Device.MLVersion? {
    currentMLVersion
  }

  func getNLModel() -> MLModel? {
    nlModel
  }

  func getNLVersion() -> MLInterfaceVersions.MLCatalog.Device.NLVersion? {
    currentNLVersion
  }

  func getVPSMLModelParams() -> VPSMLModelParams? {
    mlParams
  }

  func getVPSNLModelParams() -> VPSNLModelParams? {
    nlParams
  }

  func load(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion) -> AnyPublisher<Void, Error> {
    if currentMLVersion?.version == mlVersion.version {
      return Result { try handleModel(id: mlVersion.id, type: .ml) }
        .publisher
        .eraseToAnyPublisher()
    }

    guard let url = URL(string: mlVersion.modelUrl) else { return .fail(with: TT2Error.missingData) }

    currentMLVersion = nil
    return fetchModel(url: url, id: mlVersion.id, type: .ml)
  }

  func load(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion) -> AnyPublisher<Void, Error> {
    if currentNLVersion?.version == nlVersion.version {
      return Result { try handleModel(id: nlVersion.id, type: .nl)}
        .publisher
        .eraseToAnyPublisher()
    }

    guard let url = URL(string: nlVersion.modelUrl) else { return .fail(with: TT2Error.missingData) }

    currentNLVersion = nil
    return fetchModel(url: url, id: nlVersion.id, type: .nl)
  }

  func set(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion) {
    currentMLVersion = mlVersion
  }

  func set(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion) {
    currentNLVersion = nlVersion
  }
}

private extension MLRepository {
  func compileModel(path: URL) -> AnyPublisher<URL, Error> {
    Future { (promise) in
      if #available(iOS 16.0, *) {
        MLModel.compileModel(at: path, completionHandler: promise)
      } else {
        promise(Result { try MLModel.compileModel(at: path) })
      }
    }
    .eraseToAnyPublisher()
  }

  func buildModel(path: URL) -> MLModel? {
    let config = MLModelConfiguration()
    config.computeUnits = .all
    return try? MLModel(contentsOf: path, configuration: config)
  }

  func handleModel(id: String, type: ModelTypeEnum, data: Data? = nil) throws {
    guard let path = pathDirectory, let pathEncrypted = type == .ml ? pathEncryptedML : pathEncryptedNL else { return }
    if let data = data {
      try data.write(to: pathEncrypted, options: .atomic)
    }
    guard let decrypted = try decrypt(id: id, at: pathEncrypted) else { throw NSError(domain: "Can't decrypt", code: 500) }
    try unzipInMemory(type: type, data: decrypted, to: path)
  }

  func decrypt(id: String, at sourceURL: URL) throws -> Data? {
    guard let data = FileManager.default.contents(atPath: sourceURL.relativePath) else { throw NSError(domain: "Gunnis did not like this", code: 500) }
    return CommonCryptoAES(key: id.gunnis, data: data).decrypt()
  }

  func unzipInMemory(type: ModelTypeEnum, data: Data, to destinationURL: URL) throws {
    guard let archive = Archive(data: data, accessMode: .read) else { throw NSError(domain: "Can't create archive", code: 500) } // TODO: Better error
    try archive.filter({ !$0.path.contains("__MACOSX/") }).forEach { [weak self] (entry) in
      //Logger(verbosity: .debug).log(tag: tag, message: "PATH \(entry.path)")
      if entry.path.hasSuffix(".mlpackage/") {
        var modelName = entry.path
        modelName.removeLast(".mlpackage/".count)
        //Logger(verbosity: .debug).log(tag: tag, message: "SAVE PATH COMPONENT \(modelName)")
        switch type {
        case .ml: self?.mlModelName = modelName
        case .nl: self?.nlModelName = modelName
        }
      }
      _ = try archive.extract(entry, to: destinationURL.appendingPathComponent(entry.path))
    }
  }
}

private extension String {
  var gunnis: String { Gunnis().gunnis(input: self) }
}

private extension Array where Element == String {
  var convert: [VPSFeaturesEntriesEnum]? {
    let converted = map({ VPSFeaturesEntriesEnum(rawValue: $0.lowercased()) }).compactMap({ $0 })
    return converted.count == count ? converted : nil
  }
}
