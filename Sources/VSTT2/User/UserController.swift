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

  private var config: EnvironmentConfig?
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

  func deleteUser(userId: String, completion: @escaping (Error?) -> Void) {
    deleteUser(userId, vpsProfile: nil, completion: completion)
  }
}

extension UserController {
  func setup(clientId: Int64, positionServiceSettings: PositionServiceSettings? = nil, config: EnvironmentConfig?) {
    self.config = config
    self.clientId = clientId
    self.positionServiceSettings = positionServiceSettings
  }

  func setUser(_ userId: String, mlData: PersonalMLDataDTO, completion: @escaping (Error?) -> Void) {
    guard let clientId = clientId else { return }
    let parameters = PutUserParameters(clientId: clientId, userId: userId, mlData: [mlData], config: config)
    putUserService
      .call(with: parameters)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error):
          Logger(verbosity: .debug).log(message: error.localizedDescription)
          DispatchQueue.main.async { completion(error) }
        }
      } receiveValue: { (_) in
        DispatchQueue.main.async { completion(nil) }
      }.store(in: &cancellable)
  }

  func getUser(userId: String, completion: @escaping (Error?) -> Void) {
    guard let clientId = clientId else { return }
    let parameters = GetUserParameters(clientId: clientId, userid: userId, config: config)
    getUserService
      .call(with: parameters)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error):
          Logger(verbosity: .debug).log(message: error.localizedDescription)
          DispatchQueue.main.async { completion(error) }
        }
      } receiveValue: { [weak self] (profile) in
        self?.mlData = profile
        DispatchQueue.main.async { completion(nil) }
      }.store(in: &cancellable)
  }

  func deleteUser(_ userId: String, vpsProfile: VPSProfileDto?, completion: @escaping (Error?) -> Void) {
    guard let clientId = clientId else { return }
    let parameters = DeleteUserParameters(clientId: clientId, userId: userId, vpsProfile: vpsProfile, config: config)
    deleteUserService
      .call(with: parameters)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error):
          Logger(verbosity: .debug).log(message: error.localizedDescription)
          DispatchQueue.main.async { completion(error) }
        }
      } receiveValue: { [weak self] (_) in
        self?.vpsProfile = nil
        self?.userId = nil
        self?.clientId = nil
      }.store(in: &cancellable)
  }
}
