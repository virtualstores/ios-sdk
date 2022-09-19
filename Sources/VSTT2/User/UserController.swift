//
//  UserController.swift
//  
//
//  Created by Théodore Roos on 2022-09-14.
//

import Combine
import Foundation
import VSFoundation

public class UserController {
  @Inject var putUserService: PutUserService
  @Inject var getUserService: GetUserService
  @Inject var deleteUserService: DeleteUserService

  var vpsProfile: [String:String]?

  private var config: EnvironmentConfig?
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

  init() {}

  func setup(clientId: Int64, config: EnvironmentConfig?) {
    self.config = config
    self.clientId = clientId
    if let userId = userId {
      self.getUser(userId: userId) { (error) in
        if let error = error {
          Logger(verbosity: .info).log(message: "GetUserError: \(error)")
        }
      }
    }
  }

  public func setUser(userId: String, completion: @escaping (Error?) -> Void) {
    if vpsProfile == nil {
      getUser(userId: userId, completion: completion)
    } else {
      setUser(userId, vpsProfile: nil, completion: completion)
    }
  }

  func setUser(_ userId: String, vpsProfile: VPSProfileDto?, completion: @escaping (Error?) -> Void) {
    guard let clientId = clientId else { return }
    let parameters = PutUserParameters(clientId: clientId, userId: userId, vpsProfile: vpsProfile, config: config)
    putUserService
      .call(with: parameters)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error):
          Logger(verbosity: .debug).log(message: error.localizedDescription)
          DispatchQueue.main.async { completion(error) }
        }
      } receiveValue: { [weak self] (_) in
        self?.userId = userId
        self?.clientId = clientId
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
        self?.vpsProfile = !profile.isEmpty ? profile : nil
        DispatchQueue.main.async { completion(nil) }
      }.store(in: &cancellable)
  }

  public func deleteUser(userId: String, completion: @escaping (Error?) -> Void) {
    deleteUser(userId, vpsProfile: nil, completion: completion)
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
