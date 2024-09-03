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
  @Inject var getMLVersion: GetMLVersionUseCase
  @Inject var getNLModel: GetNLModelUseCase
  @Inject var getNLVersion: GetNLVersionUseCase
  @Inject var getTT2Settings: GetCurrentTT2SettingsUseCase
  @Inject var getVPSMLModelParams: GetVPSMLModelParamsUseCase
  @Inject var getVPSNLModelParams: GetVPSNLModelParamsUseCase
  @Inject var loadMLVersion: LoadMLVersionUseCase
  @Inject var loadNLVersion: LoadNLVersionUseCase
  @Inject var setMLVersion: SetMLVersionUseCase
  @Inject var setNLVersion: SetNLVersionUseCase

  init() {
    fetchMLInterfaceVersions.invoke { [weak self] (error) in
      if let error = error {
        print("File", "Error getting Version", error)
      } else if let catalog = self?.getMLCatalog.invoke(), let settings = self?.getTT2Settings.invoke() {
        self?.handle(mlCatalog: catalog, params: settings.params)
      }
    }
  }

  func handle(mlCatalog: MLInterfaceVersions.MLCatalog, params: TT2Settings.TT2ModelParams) {
    if let version = mlCatalog.getLatestSupportedVelocityModel(params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      //print("MLVersion", mlVersion)
      loadMLVersion.invoke(version: version) { [weak self] (error) in
        if let error = error {
          print("Error loading MLVersion", error)
          return
        }
        self?.setMLVersion.invoke(version: version)
        self?.compileModel.invoke(type: .ml) { (error) in
          if let error = error {
            print("Error compiling MLVersion", error)
          }
        }
      }
    }
    if let version = mlCatalog.getLatestSupportedNLModel(params: params, sdkVersion: TT2.version, vpsVersion: vpsVersion) {
      loadNLVersion.invoke(version: version) { [weak self] (error) in
        if let error = error {
          print("Error loading NLVersion", error)
          return
        }
        self?.setNLVersion.invoke(version: version)
        self?.compileModel.invoke(type: .nl) { (error) in
          if let error = error {
            print("Error compiling NLVersion", error)
          }
        }
      }
    }
  }
}

extension VSMLModelManager: VPSModelManager {
  var mlModel: MLModel? { getMLModel.invoke() }
  var nlModel: MLModel? { getNLModel.invoke() }
  var mlParams: VPSMLModelParams? { getVPSMLModelParams.invoke() }
  var nlParams: VPSNLModelParams? { getVPSNLModelParams.invoke() }
}

extension Array {
  func split(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size)
      .map { Array(self[$0..<Swift.min($0 + size, count)]) }
  }
}
