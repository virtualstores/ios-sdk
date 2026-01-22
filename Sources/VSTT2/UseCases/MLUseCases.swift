//
//  MLUseCases.swift
//
//
//  Created by Théodore Roos on 2024-05-30.
//

import Combine
import CoreML
import Foundation
import VSFoundation

class CompileModelUseCase {
  @Inject var repository: IMLRepository

  func invoke(type: MLInterfaceVersions.MLCatalog.ModelTypeEnum) -> AnyPublisher<Void, Error> {
    repository.compileModel(type: type)
  }
}

class FetchMLInterfaceVersionsUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> AnyPublisher<Void, Error> {
    repository.fetchMLInterfaceVersions()
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

  func invoke(_ type: MLInterfaceVersions.MLCatalog.ModelTypeEnum, version: DeviceVersioning) -> AnyPublisher<Void, Error> {
    switch type {
    case .ml:
      guard
        let version = version as? MLInterfaceVersions.MLCatalog.Device.MLVersion
      else { return .fail(with: NSError(domain: "Failed to load ML version", code: 400)) }
      return repository.load(mlVersion: version)
    case .nl:
      guard
        let version = version as? MLInterfaceVersions.MLCatalog.Device.NLVersion
      else { return .fail(with: NSError(domain: "Failed to load ML version", code: 400)) }
      return repository.load(nlVersion: version)
    case .np:
      guard
        let version = version as? MLInterfaceVersions.MLCatalog.Device.NPVersion
      else { return .fail(with: NSError(domain: "Failed to load ML version", code: 400)) }
      return repository.load(npVersion: version)
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
