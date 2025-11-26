//
//  VSMLModelManager.swift
//  
//
//  Created by Théodore Roos on 2023-03-07.
//

import Combine
import CoreML
import Foundation
import VSFoundation
import VSPositionKit

class VSMLModelManager {
  @Inject var compileModel: CompileModelUseCase
  @Inject var fetchMLInterfaceVersions: FetchMLInterfaceVersionsUseCase
  @Inject var getMLCatalog: GetMLCatalogUseCase
  @OptionalInject var getMLModel: GetMLModelUseCase?
  @Inject var getMLVersion: GetMLVersionUseCase
  @OptionalInject var getNLModel: GetNLModelUseCase?
  @Inject var getNLVersion: GetNLVersionUseCase
  @Inject var getTT2Settings: GetCurrentTT2SettingsUseCase
  @OptionalInject var getVPSMLModelParams: GetVPSMLModelParamsUseCase?
  @OptionalInject var getVPSNLModelParams: GetVPSNLModelParamsUseCase?
  @Inject var loadMLVersion: LoadMLVersionUseCase
  @Inject var loadNLVersion: LoadNLVersionUseCase
  @Inject var setMLVersion: SetMLVersionUseCase
  @Inject var setNLVersion: SetNLVersionUseCase

  private let tag = "VSMLModelManager"

  func fetchInterface(completion: @escaping (Error?) -> Void) {
    fetchMLInterfaceVersions.invoke { [weak self] (error) in
      if let error = error {
        Logger(verbosity: .warning).log(message: "Error getting InterfceVersions: \(error)")
        completion(error)
      } else if let catalog = self?.getMLCatalog.invoke(), let settings = self?.getTT2Settings.invoke() {
        self?.handle(mlCatalog: catalog, params: settings.params, completion: completion)
      }
    }
  }

  func handle(mlCatalog: MLInterfaceVersions.MLCatalog, params: TT2Settings.TT2ModelParams, completion: @escaping (Error?) -> ()) {
    if let version = mlCatalog.getLatestSupportedVelocityModel(params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      loadMLVersion.invoke(version: version) { [weak self] (error) in
        if let error = error {
          Logger(verbosity: .warning).log(message: "Error loading MLVersion: \(error)")
          return
        }
        self?.setMLVersion.invoke(version: version)
        self?.compileModel.invoke(type: .ml) { (error) in
          if let error = error {
            Logger(verbosity: .warning).log(message: "Error compiling MLVersion: \(error)")
          }
          completion(error)
        }
      }
    } else {
      completion(TT2Error.missingData)
    }
    if let version = mlCatalog.getLatestSupportedNLModel(params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      loadNLVersion.invoke(version: version) { [weak self] (error) in
        if let error = error {
          Logger(verbosity: .warning).log(message: "Error loading NLVersion: \(error)")
          return
        }
        self?.setNLVersion.invoke(version: version)
        self?.compileModel.invoke(type: .nl) { (error) in
          if let error = error {
            Logger(verbosity: .warning).log(message: "Error compiling NLVersion: \(error)")
          }
        }
      }
    }
  }

  func fetchInterface() -> AnyPublisher<Void, Error> {
    fetchMLInterfaceVersions.invoke()
      .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
        guard
          let self = self,
          let catalog = getMLCatalog.invoke()
        else { return .fail(with: TT2Error.missingData) }
        return handle(mlCatalog: catalog, params: getTT2Settings.invoke().params)
      }
      .eraseToAnyPublisher()
  }

  func handle(mlCatalog: MLInterfaceVersions.MLCatalog, params: TT2Settings.TT2ModelParams) -> AnyPublisher<Void, Error> {
    var publishers = [AnyPublisher<Void, Error>]()
    if let version = mlCatalog.getLatestSupportedVelocityModel(params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      publishers.append(handle(version: version))
    }
    if let version = mlCatalog.getLatestSupportedNLModel(params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      publishers.append(handle(version: version))
    }
    return Publishers.MergeMany(publishers).eraseToAnyPublisher()
  }

  func handle(version: MLInterfaceVersions.MLCatalog.Device.MLVersion) -> AnyPublisher<Void, Error> {
    loadMLVersion.invoke(version: version)
      .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
        guard let self = self else { return .fail(with: TT2Error.missingData) }
        setMLVersion.invoke(version: version)
        return compileModel.invoke(type: .ml).eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }

  func handle(version: MLInterfaceVersions.MLCatalog.Device.NLVersion) -> AnyPublisher<Void, Error> {
    loadNLVersion.invoke(version: version)
      .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
        guard let self = self else { return .fail(with: TT2Error.missingData) }
        setNLVersion.invoke(version: version)
        return compileModel.invoke(type: .nl).eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }
}

extension VSMLModelManager: VPSModelManager {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
    getMLModel = nil
    getNLModel = nil
    getVPSMLModelParams = nil
    getVPSNLModelParams = nil
  }
  
  var mlModel: MLModel? { getMLModel?.invoke() }
  var nlModel: MLModel? { getNLModel?.invoke() }
  var mlParams: VPSMLModelParams? { getVPSMLModelParams?.invoke() }
  var nlParams: VPSNLModelParams? { getVPSNLModelParams?.invoke() }
}

extension Array {
  func split(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size)
      .map { Array(self[$0..<Swift.min($0 + size, count)]) }
  }
}
