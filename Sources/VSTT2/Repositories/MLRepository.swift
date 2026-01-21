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
  func compileModel(type: MLInterfaceVersions.MLCatalog.ModelTypeEnum, completion: @escaping (Error?) -> ())
  func fetchMLInterfaceVersions(completion: @escaping (Error?) -> ())
  func fetchModel(url: URL, id: String, type: MLInterfaceVersions.MLCatalog.ModelTypeEnum) -> AnyPublisher<Void, Error>
  func getMLCatalog() -> MLInterfaceVersions.MLCatalog?
  func getMLModel() -> MLModel?
  func getMLVersion() -> MLInterfaceVersions.MLCatalog.Device.MLVersion?
  func getNLModel() -> MLModel?
  func getNLVersion() -> MLInterfaceVersions.MLCatalog.Device.NLVersion?
  func getNPModel() -> MLModel?
  func getNPVersion() -> MLInterfaceVersions.MLCatalog.Device.NPVersion?
  func getVPSMLModelParams() -> VPSMLModelParams?
  func getVPSNLModelParams() -> VPSNLModelParams?
  func load(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion, completion: @escaping (Error?) -> ())
  func load(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion, completion: @escaping (Error?) -> ())
  func load(npVersion: MLInterfaceVersions.MLCatalog.Device.NPVersion, completion: @escaping (Error?) -> ())
  func set(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion)
  func set(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion)
  func set(npVersion: MLInterfaceVersions.MLCatalog.Device.NPVersion)
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
  private var currentNPVersion: MLInterfaceVersions.MLCatalog.Device.NPVersion? {
    get {
      guard let data = UserDefaults.standard.value(forKey: "TT2CURRENTMLCATALOGNPVERSION") as? Data else { return nil }
      return try? JSONDecoder().decode(MLInterfaceVersions.MLCatalog.Device.NPVersion.self, from: data)
    }
    set {
      guard let encoded = try? JSONEncoder().encode(newValue) else { return }
      UserDefaults.standard.setValue(encoded, forKey: "TT2CURRENTMLCATALOGNPVERSION")
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
  private var npModel: MLModel?
  private var mlModelName = ""
  private var nlModelName = ""
  private var npModelName = ""
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
  private var pathNPModel: URL? {
    pathDirectory?
      .appendingPathComponent(npModelName).appendingPathExtension("mlpackage")
  }
  private var pathEncryptedML: URL? { pathDirectory?.appendingPathExtension("ml.encrypted") }
  private var pathEncryptedNL: URL? { pathDirectory?.appendingPathExtension("nl.encrypted") }
  private var pathEncryptedNP: URL? { pathDirectory?.appendingPathExtension("np.encrypted") }
  private var cancellables = Set<AnyCancellable>()

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
  
  func compileModel(type: MLInterfaceVersions.MLCatalog.ModelTypeEnum, completion: @escaping (Error?) -> ()) {
    compileModel(type: type)
      .asFailure()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }

  func compileModel(type: MLInterfaceVersions.MLCatalog.ModelTypeEnum) -> AnyPublisher<Void, Error> {
    let path: URL?
    switch type {
    case .ml: path = pathMLModel
    case .nl: path = pathNLModel
    case .np: path = pathNPModel
    }
    guard let path = path else {
      return Fail(error: TT2Error.missingData).eraseToAnyPublisher()
    }
    return compileModel(path: path)
      .tryMap { [weak self] in
        guard let model = self?.buildModel(path: $0) else { throw NSError(domain: "Can't build model", code: 500) } // TODO: Better error
        switch type {
        case .ml: self?.mlModel = model
        case .nl: self?.nlModel = model
        case .np: self?.npModel = model
        }
        try? FileManager.default.removeItem(at: path)
        try? FileManager.default.removeItem(at: $0)
      }
      .eraseToAnyPublisher()
  }

  func fetchMLInterfaceVersions(completion: @escaping (Error?) -> ()) {
    api.fetchMLInterfaceVersions()
      .map { [weak self] in self?.catalog = $0.mlCatalog }
      .asFailure()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }

  func fetchModel(url: URL, id: String, type: MLInterfaceVersions.MLCatalog.ModelTypeEnum) -> AnyPublisher<Void, Error> {
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

  func getNPModel() -> MLModel? {
    npModel
  }
  func getNPVersion() -> MLInterfaceVersions.MLCatalog.Device.NPVersion? {
    currentNPVersion
  }

  func getVPSMLModelParams() -> VPSMLModelParams? {
    mlParams
  }

  func getVPSNLModelParams() -> VPSNLModelParams? {
    nlParams
  }

  func load(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion, completion: @escaping (Error?) -> ()) {
    load(mlVersion: mlVersion)
      .asFailure()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }

  func load(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion) -> AnyPublisher<Void, Error> {
    if currentMLVersion?.version == mlVersion.version {
      return Result { try handleModel(id: mlVersion.id, type: .ml) }
        .publisher
        .eraseToAnyPublisher()
    }

    guard let url = URL(string: mlVersion.modelUrl) else {
      return Fail(error: TT2Error.missingData).eraseToAnyPublisher()
    }

    currentMLVersion = nil
    return fetchModel(url: url, id: mlVersion.id, type: .ml)
  }

  func load(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion, completion: @escaping (Error?) -> ()) {
    load(nlVersion: nlVersion)
      .asFailure()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }

  func load(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion) -> AnyPublisher<Void, Error> {
    if currentNLVersion?.version == nlVersion.version {
      return Result { try  handleModel(id: nlVersion.id, type: .nl)}
        .publisher
        .eraseToAnyPublisher()
    }

    guard let url = URL(string: nlVersion.modelUrl) else {
      return Fail(error: TT2Error.missingData).eraseToAnyPublisher()
    }

    currentNLVersion = nil
    return fetchModel(url: url, id: nlVersion.id, type: .nl)
  }

  func load(npVersion: MLInterfaceVersions.MLCatalog.Device.NPVersion, completion: @escaping (Error?) -> ()) {
    load(npVersion: npVersion)
      .asFailure()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }

  func load(npVersion: MLInterfaceVersions.MLCatalog.Device.NPVersion) -> AnyPublisher<Void, Error> {
    if currentNPVersion?.version == npVersion.version {
      return Result { try handleModel(id: npVersion.id, type: .np)}
        .publisher
        .eraseToAnyPublisher()
    }

    guard let url = URL(string: npVersion.modelUrl) else {
      return Fail(error: TT2Error.missingData).eraseToAnyPublisher()
    }

    currentNPVersion = nil
    return fetchModel(url: url, id: npVersion.id, type: .np)
  }

  func set(mlVersion: MLInterfaceVersions.MLCatalog.Device.MLVersion) {
    currentMLVersion = mlVersion
  }

  func set(nlVersion: MLInterfaceVersions.MLCatalog.Device.NLVersion) {
    currentNLVersion = nlVersion
  }

  func set(npVersion: MLInterfaceVersions.MLCatalog.Device.NPVersion) {
    currentNPVersion = npVersion
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

  func handleModel(id: String, type: MLInterfaceVersions.MLCatalog.ModelTypeEnum, data: Data? = nil) throws {
    let pathEncrypted: URL? = {
      switch type {
      case .ml: return pathEncryptedML
      case .nl: return pathEncryptedNL
      case .np: return pathEncryptedNP
      }
    }()
    guard let path = pathDirectory, let pathEncrypted = pathEncrypted else { return }
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

  func unzipInMemory(type: MLInterfaceVersions.MLCatalog.ModelTypeEnum, data: Data, to destinationURL: URL) throws {
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
        case .np: self?.npModelName = modelName
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
