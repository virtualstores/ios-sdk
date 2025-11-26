//
//  AuthUseCases.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-02-03.
//

import Combine
import VSFoundation

class GetApiKeyUseCase {
  @Inject var repository: IApiKeyRepository

  func invoke(for type: RoutingType) -> String? {
    repository.get(for: type)
  }
}

class GetAuthSettingsUseCase {
  @Inject var repository: IAuthRepository

  func invoke() -> AuthSettings? {
    repository.getAuthSettings()
  }
}

class GetAuthTokenUseCase {
  @Inject var repository: IJWTTokenRepository

  func invoke() -> String? {
    repository.getAuthJWT()
  }
}

class GetRefreskTokenUseCase {
  @Inject var repository: IJWTTokenRepository

  func invoke() -> String? {
    repository.getRefreshJWT()
  }
}

class LoginUseCase {
  @Inject var repository: IAuthRepository
  @Inject var apiKeyRepository: IApiKeyRepository
  @Inject var jwtRepository: IJWTTokenRepository

  func invoke() -> AnyPublisher<Void, Error> {
    guard let settings = repository.getAuthSettings() else { return .fail(with: TT2Error.missingData) }
    switch settings {
    case .apiKey(let key):
      apiKeyRepository.set(for: .central, value: key)
      return Empty(completeImmediately: true).eraseToAnyPublisher()
    case .tokenBased(let login):
      return repository.login(username: login.username, password: login.password)
        .handleEvents(receiveOutput: { [weak self] in
          self?.jwtRepository.save(accessJWT: $0.authToken)
          self?.jwtRepository.save(refreshJWT: $0.refreshToken)
        })
        .map { _ in () }
        .eraseToAnyPublisher()
    }
  }
}

class RefreshUseCase {
  @Inject var authRepository: IAuthRepository
  @Inject var jwtRepository: IJWTTokenRepository

  func invoke() -> AnyPublisher<Void, Error> {
    guard
      let authToken = jwtRepository.getAuthJWT(),
      let refreshToken = jwtRepository.getRefreshJWT()
    else { return .fail(with: NetworkError.invalidTokens) }

    return authRepository
      .refresh(authToken: authToken, refreshToken: refreshToken)
      .map { [weak self] (dto) in
        self?.jwtRepository.save(accessJWT: dto.authToken)
        return ()
      }
      .eraseToAnyPublisher()
  }
}

class SetApiKeyUseCase {
  @Inject var repository: IApiKeyRepository

  func invoke(type: RoutingType, value: String) {
    repository.set(for: type, value: value)
  }
}

class SetAuthSettingsUseCase {
  @Inject var repository: IAuthRepository

  func invoke(settings: AuthSettings) {
    repository.set(authSettings: settings)
  }
}
