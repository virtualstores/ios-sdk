//
//  UserController.swift
//  
//
//  Created by Théodore Roos on 2022-09-14.
//

import Combine
import Foundation
import VSFoundation

struct UserControllerBusiness {
  func getVPSSettings(positionServiceSettings: PositionServiceSettings?) -> VPSSettings {
    var mlAlgos: [PersonalMLAlgorithm] = []
    if let positionServiceSettings = positionServiceSettings {
      if positionServiceSettings.useCoefficientOptimizer {
        mlAlgos.append(.coefficientOptimizer)
      }
      if positionServiceSettings.useDriftCompensator {
        mlAlgos.append(.driftCompensator)
      }
    } else {
      mlAlgos.append(.coefficientOptimizer)
    }

    return VPSSettings(mlAlgos: !mlAlgos.isEmpty ? mlAlgos : nil, useML: positionServiceSettings?.useML ?? true, mlAlgo: .coefficientOptimizer)
  }
}

public class UserController {
  @Inject var putUserService: PutUserService
  @Inject var getUserService: GetUserService
  @Inject var deleteUserService: DeleteUserService

  var vpsProfile: [String:String]?
  var mlData: [VPSProfileDto2]?

  private var positionServiceSettings: PositionServiceSettings?
  private var cancellable = Set<AnyCancellable>()

  let defaults = UserDefaults.standard
  var userId: String? {
    set { defaults.set(newValue, forKey: "TT2USERID") }
    get { defaults.string(forKey: "TT2USERID") }
  }
  var clientId: Int64? {
    set { defaults.set(newValue, forKey: "TT2USERCLIENTID") }
    get { defaults.object(forKey: "TT2USERCLIENTID") as? Int64 }
  }
}

extension UserController: IUserController {
  public func getVPSSettings() -> VPSSettings {
    UserControllerBusiness().getVPSSettings(positionServiceSettings: positionServiceSettings)
  }

  public func getVPSMLParamPackage(mlAlgorithm: PersonalMLAlgorithm) -> [PersonalMLDataDTO] {
    var data = [PersonalMLDataDTO]()
    mlData?.forEach { (profile) in
      guard let mlAlgo = profile.mlAlgorithms.first(where: { $0.type == mlAlgorithm }) else { return }
      mlAlgo.orientationModes.compactMap { $0 }.forEach { (orientationMode) in
        data.append(contentsOf: orientationMode.personalMLData)
      }
    }
    return data
  }
}

public extension UserController {
  func initializeUser(userId: String, completion: @escaping (Error?) -> Void) {
    getUser(userId: userId, completion: completion)
    self.userId = userId
  }

  /// Only use for development purposes
  func deleteUser(userId: String, completion: @escaping (Error?) -> Void) {
    deleteUser(userId, completion: completion)
  }
}

extension UserController {
  func setup(clientId: Int64, positionServiceSettings: PositionServiceSettings? = nil) {
    self.clientId = clientId
    self.positionServiceSettings = positionServiceSettings
  }

  func updateUserML(_ userId: String, mlData: PersonalMLDataDTO) -> AnyPublisher<Void, Error> {
    guard let clientId = clientId else { return .fail(with: TT2Error.missingData) }
    return putUserService
      .call(with: .init(clientId: clientId, userId: userId, mlData: [mlData]))
      .eraseToAnyPublisher()
  }

  func getUser(userId: String) -> AnyPublisher<Void, Error> {
    guard let clientId = clientId else { return .fail(with: TT2Error.missingData) }
    return getUserService
      .call(with: .init(clientId: clientId, userid: userId))
      .handleEvents(receiveOutput: { [weak self] (profiles) in
        self?.mlData = profiles
      })
      .map { (_) in () }
      .eraseToAnyPublisher()
  }

  func deleteUser(_ userId: String) -> AnyPublisher<Void, Error> {
    guard let clientId = clientId else { return .fail(with: TT2Error.missingData) }
    return deleteUserService
      .call(with: .init(clientId: clientId, userId: userId))
      .handleEvents(receiveOutput: { [weak self] () in
        self?.vpsProfile = nil
        self?.userId = nil
      })
      .eraseToAnyPublisher()
  }
}

private extension UserController {
  func updateUserML(_ userId: String, mlData: PersonalMLDataDTO, completion: @escaping (Error?) -> Void) {
    updateUserML(userId, mlData: mlData)
      .asFailure()
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: completion)
      .store(in: &cancellable)
  }

  func getUser(userId: String, completion: @escaping (Error?) -> Void) {
    getUser(userId: userId)
      .asFailure()
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: completion)
      .store(in: &cancellable)
  }

  func deleteUser(_ userId: String, completion: @escaping (Error?) -> Void) {
    deleteUser(userId)
      .asFailure()
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: { (error) in
        if let error = error {
          Logger(verbosity: .debug).log(message: error.localizedDescription)
        }
        completion(error)
      })
      .store(in: &cancellable)
  }
}
