//
//  MLUseCases.swift
//
//
//  Created by Théodore Roos on 2024-05-30.
//

import CoreML
import Foundation
import VSFoundation

class CompileModelUseCase {
  @Inject var repository: IMLRepository

  func invoke(type: MLInterfaceVersions.MLCatalog.ModelTypeEnum, completion: @escaping (Error?) -> ()) {
    repository.compileModel(type: type, completion: completion)
  }
}

class FetchMLInterfaceVersionsUseCase {
  @Inject var repository: IMLRepository

  func invoke(completion: @escaping (Error?) -> ()) {
    repository.fetchMLInterfaceVersions(completion: completion)
  }
}

// MARK: - Getters
class GetMLCatalogUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> MLInterfaceVersions.MLCatalog? {
    repository.getMLCatalog()
  }
}

class GetMLModelUseCase {
  @Inject var repository: IMLRepository

  func invoke(_ type: MLInterfaceVersions.MLCatalog.ModelTypeEnum) -> MLModel? {
    switch type {
    case .ml: return repository.getMLModel()
    case .nl: return repository.getNLModel()
    case .np: return repository.getNPModel()
    }
  }
}

class GetMLVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> MLInterfaceVersions.MLCatalog.Device.MLVersion? {
    repository.getMLVersion()
  }
}

class GetNLVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> MLInterfaceVersions.MLCatalog.Device.NLVersion? {
    repository.getNLVersion()
  }
}

class GetNPVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> MLInterfaceVersions.MLCatalog.Device.NPVersion? {
    repository.getNPVersion()
  }
}

class GetVPSMLModelParamsUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> VPSMLModelParams? {
    repository.getVPSMLModelParams()
  }
}

class GetVPSNLModelParamsUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> VPSNLModelParams? {
    repository.getVPSNLModelParams()
  }
}

// MARK: - Loaders
class LoadModelVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke(_ type: MLInterfaceVersions.MLCatalog.ModelTypeEnum, version: DeviceVersioning, completion: @escaping (Error?) -> ()) {
    switch type {
    case .ml:
      guard let version = version as? MLInterfaceVersions.MLCatalog.Device.MLVersion else { return }
      repository.load(mlVersion: version, completion: completion)
    case .nl:
      guard let version = version as? MLInterfaceVersions.MLCatalog.Device.NLVersion else { return }
      repository.load(nlVersion: version, completion: completion)
    case .np:
      guard let version = version as? MLInterfaceVersions.MLCatalog.Device.NPVersion else { return }
      repository.load(npVersion: version, completion: completion)
    }
  }
}

// MARK: - Setters
class SetModelVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke(_ type: MLInterfaceVersions.MLCatalog.ModelTypeEnum, version: DeviceVersioning) {
    switch type {
    case .ml:
      guard let version = version as? MLInterfaceVersions.MLCatalog.Device.MLVersion else { return }
      repository.set(mlVersion: version)
    case .nl:
      guard let version = version as? MLInterfaceVersions.MLCatalog.Device.NLVersion else { return }
      repository.set(nlVersion: version)
    case .np:
      guard let version = version as? MLInterfaceVersions.MLCatalog.Device.NPVersion else { return }
      repository.set(npVersion: version)
    }
  }
}
