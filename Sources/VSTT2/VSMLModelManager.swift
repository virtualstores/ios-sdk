//
//  VSMLModelManager.swift
//  
//
//  Created by Théodore Roos on 2023-03-07.
//

import Foundation
import CoreML
import VSFoundation
import VSPositionKit

class VSMLModelManager {
  @Inject var compileModel: CompileModelUseCase
  @Inject var fetchMLInterfaceVersions: FetchMLInterfaceVersionsUseCase
  @Inject var getMLCatalog: GetMLCatalogUseCase
  @Inject var getMLModel: GetMLModelUseCase
  @Inject var getTT2Settings: GetCurrentTT2SettingsUseCase
  @Inject var getVPSMLModelParams: GetVPSMLModelParamsUseCase
  @Inject var getVPSNLModelParams: GetVPSNLModelParamsUseCase
  @Inject var loadVersion: LoadModelVersionUseCase
  @Inject var setVersion: SetModelVersionUseCase

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
    if let version = mlCatalog.getLatestSupportedModel(.ml, params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      loadVersion.invoke(.ml, version: version) { [weak self] (error) in
        if let error = error {
          Logger(verbosity: .warning).log(message: "Error loading MLVersion: \(error)")
          return
        }
        self?.setVersion.invoke(.ml, version: version)
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
    if let version = mlCatalog.getLatestSupportedModel(.nl, params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      loadVersion.invoke(.nl, version: version) { [weak self] (error) in
        if let error = error {
          Logger(verbosity: .warning).log(message: "Error loading NLVersion: \(error)")
          return
        }
        self?.setVersion.invoke(.nl, version: version)
        self?.compileModel.invoke(type: .nl) { (error) in
          if let error = error {
            Logger(verbosity: .warning).log(message: "Error compiling NLVersion: \(error)")
          }
        }
      }
    }
    if let version = mlCatalog.getLatestSupportedModel(.np, params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      loadVersion.invoke(.np, version: version) { [weak self] (error) in
        if let error = error {
          Logger(verbosity: .warning).log(message: "Error loading NPVersion: \(error)")
          return
        }
        self?.setVersion.invoke(.np, version: version)
        self?.compileModel.invoke(type: .np) { (error) in
          if let error = error {
            Logger(verbosity: .warning).log(message: "Error compiling NPVersion: \(error)")
          }
        }
      }
    }
  }

  deinit {
    Logger(verbosity: .info).log(tag: tag, message: "deinit")
    dispose()
  }
}

extension VSMLModelManager: VPSModelManager {
  func dispose() {
    Logger(verbosity: .info).log(tag: tag, message: "dispose")
  }
  
  var mlModel: MLModel? { getMLModel.invoke(.ml) }
  var nlModel: MLModel? { getMLModel.invoke(.nl) }
  var npModel: MLModel? { getMLModel.invoke(.np) }
  var mlParams: VPSMLModelParams? { getVPSMLModelParams.invoke() }
  var nlParams: VPSNLModelParams? { getVPSNLModelParams.invoke() }
}

extension Array {
  func split(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size)
      .map { Array(self[$0..<Swift.min($0 + size, count)]) }
  }
}
