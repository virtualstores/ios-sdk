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

  func invoke(type: MLRepository.ModelTypeEnum, completion: @escaping (Error?) -> ()) {
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

  func invoke() -> MLModel? {
    repository.getMLModel()
  }
}

class GetMLVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> MLInterfaceVersions.MLCatalog.Device.MLVersion? {
    repository.getMLVersion()
  }
}

class GetNLModelUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> MLModel? {
    repository.getNLModel()
  }
}

class GetNLVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke() -> MLInterfaceVersions.MLCatalog.Device.NLVersion? {
    repository.getNLVersion()
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
class LoadMLVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke(version: MLInterfaceVersions.MLCatalog.Device.MLVersion, completion: @escaping (Error?) -> ()) {
    repository.load(mlVersion: version, completion: completion)
  }
}

class LoadNLVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke(version: MLInterfaceVersions.MLCatalog.Device.NLVersion, completion: @escaping (Error?) -> ()) {
    repository.load(nlVersion: version, completion: completion)
  }
}

// MARK: - Setters
class SetMLVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke(version: MLInterfaceVersions.MLCatalog.Device.MLVersion) {
    repository.set(mlVersion: version)
  }
}

class SetNLVersionUseCase {
  @Inject var repository: IMLRepository

  func invoke(version: MLInterfaceVersions.MLCatalog.Device.NLVersion) {
    repository.set(nlVersion: version)
  }
}
