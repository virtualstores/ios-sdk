//
//  MLRepository.swift
//
//
//  Created by Théodore Roos on 2024-05-30.
//

import CoreML
import Foundation
import VSFoundation
import ZIPFoundation
import vps

protocol IMLRepository: Disposable {
  func compileModel(type: MLRepository.ModelTypeEnum, completion: @escaping (Error?) -> ())
  func fetchMLInterfaceVersions(completion: @escaping (Error?) -> ())
  func fetchModel(url: URL, id: String, type: MLRepository.ModelTypeEnum, completion: @escaping (Error?) -> ())
  func getMLCatalog() -> MLInterfaceVersions.MLCatalog?
  func getMLModel() -> MLModel?
  func getMLVersion() -> MLInterfaceVersions.MLCatalog.Device.MLVersion?
  func getNLModel() -> MLModel?
  func getNLVersion() -> MLInterfaceVersions.MLCatalog.Device.NLVersion?
  func getVPSMLModelParams() -> VPSMLModelParams?
  func getVPSNLModelParams() -> VPSNLModelParams?
  func load(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion, completion: @escaping (Error?) -> ())
  func load(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion, completion: @escaping (Error?) -> ())
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
    api.dispose()
    mlModel = nil
    mlParams = nil
    nlModel = nil
    nlParams = nil
  }
  
  func compileModel(type: ModelTypeEnum, completion: @escaping (Error?) -> ()) {
    let path: URL?
    switch type {
    case .ml: path = pathMLModel
    case .nl: path = pathNLModel
    }
    guard let path = path else { return }
    compileModel(path: path) { [weak self] (result) in
      switch result {
      case .success(let url):
        guard let model = self?.buildModel(path: url) else { completion(NSError(domain: "Can't build model", code: 500)); return } // TODO: Better error
        switch type {
        case .ml: self?.mlModel = model
        case .nl: self?.nlModel = model
        }
        try? FileManager.default.removeItem(at: path)
        try? FileManager.default.removeItem(at: url)
        completion(nil)
      case .failure(let error):
        completion(error)
      }
    }
  }

  func fetchMLInterfaceVersions(completion: @escaping (Error?) -> ()) {
    api.fetchMLInterfaceVersions { [weak self] (result) in
      switch result {
      case .success(let versions):
        self?.catalog = versions.mlCatalog
        completion(nil)
      case .failure(let error):
        completion(error)
      }
    }
  }

  func fetchModel(url: URL, id: String, type: ModelTypeEnum, completion: @escaping (Error?) -> ()) {
    api.fetchModel(url: url) { [weak self] (result) in
      switch result {
      case .success(let model):
        self?.handleModel(id: id, type: type, data: model, completion: completion)
      case .failure(let error):
        completion(error)
      }
    }
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

  func load(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion, completion: @escaping (Error?) -> ()) {
    if let version = currentMLVersion, version.version == mlVersion.version {
      handleModel(id: mlVersion.id, type: .ml, completion: completion)
    } else if let url = URL(string: mlVersion.modelUrl) {
      currentMLVersion = nil
      fetchModel(url: url, id: mlVersion.id, type: .ml, completion: completion)
    }
  }

  func load(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion, completion: @escaping (Error?) -> ()) {
    if let version = currentNLVersion, version.version == nlVersion.version {
      handleModel(id: nlVersion.id, type: .nl, completion: completion)
    } else if let url = URL(string: nlVersion.modelUrl) {
      currentNLVersion = nil
      fetchModel(url: url, id: nlVersion.id, type: .nl, completion: completion)
    }
  }

  func set(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion) {
    currentMLVersion = mlVersion
  }

  func set(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion) {
    currentNLVersion = nlVersion
  }
}

private extension MLRepository {
  func compileModel(path: URL, completion: @escaping (Result<URL, Error>) -> Void) {
    if #available(iOS 16.0, *) {
      MLModel.compileModel(at: path, completionHandler: completion)
    } else {
      do {
        completion(.success(try MLModel.compileModel(at: path)))
      } catch {
        completion(.failure(error))
      }
    }
  }

  func buildModel(path: URL) -> MLModel? {
    let config = MLModelConfiguration()
    config.computeUnits = .all
    return try? MLModel(contentsOf: path, configuration: config)
  }

  func handleModel(id: String, type: ModelTypeEnum, data: Data? = nil, completion: @escaping (Error?) -> ()) {
    do {
      guard let path = pathDirectory, let pathEncrypted = type == .ml ? pathEncryptedML : pathEncryptedNL else { return }
      if let data = data {
        try data.write(to: pathEncrypted, options: .atomic)
      }
      guard let decrypted = try decrypt(id: id, at: pathEncrypted) else { throw NSError(domain: "Can't decrypt", code: 500) }
      try unzipInMemory(type: type, data: decrypted, to: path)
      completion(nil)
    } catch {
      completion(error)
    }
  }

  func decrypt(id: String, at sourceURL: URL) throws -> Data? {
    guard let data = FileManager.default.contents(atPath: sourceURL.relativePath) else { throw NSError(domain: "Gunnis did not like this", code: 500) }
    return CommonCryptoAES(key: id.gunnis, data: data).decrypt()
  }

  func unzipInMemory(type: ModelTypeEnum, data: Data, to destinationURL: URL) throws {
    guard let archive = Archive(data: data, accessMode: .read) else { throw NSError(domain: "Can't create archive", code: 500) } // TODO: Better error
    try archive.filter({ !$0.path.contains("__MACOSX/") }).forEach { [weak self] (entry) in
      //print("PATH", entry.path)
      if entry.path.hasSuffix(".mlpackage/") {
        var modelName = entry.path
        modelName.removeLast(".mlpackage/".count)
        //print("SAVE PATH COMPONENT", modelName)
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
