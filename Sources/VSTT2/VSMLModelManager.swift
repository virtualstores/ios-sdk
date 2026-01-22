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
  @Inject var getMLModel: GetMLModelUseCase
  @Inject var getTT2Settings: GetCurrentTT2SettingsUseCase
  @Inject var getVPSMLModelParams: GetVPSMLModelParamsUseCase
  @Inject var getVPSNLModelParams: GetVPSNLModelParamsUseCase
  @Inject var loadVersion: LoadModelVersionUseCase
  @Inject var setVersion: SetModelVersionUseCase

  private let tag = "VSMLModelManager"

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
    if let version = mlCatalog.getLatestSupportedModel(.ml, params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      publishers.append(handle(.ml, version: version))
    }
    guard !publishers.isEmpty else { return .fail(with: TT2Error.missingData) }
    if let version = mlCatalog.getLatestSupportedModel(.nl, params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      publishers.append(handle(.nl, version: version))
    }
    if let version = mlCatalog.getLatestSupportedModel(.np, params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      publishers.append(handle(.np, version: version))
    }

    return Publishers.MergeMany(publishers).eraseToAnyPublisher()
  }

  func handle(_ type: MLInterfaceVersions.MLCatalog.ModelTypeEnum, version: DeviceVersioning) -> AnyPublisher<Void, Error> {
    loadVersion.invoke(type, version: version)
      .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
        guard let self = self else { return .fail(with: TT2Error.missingData) }
        setVersion.invoke(type, version: version)
        return compileModel.invoke(type: type).eraseToAnyPublisher()
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
