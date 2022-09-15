//
//  UserService.swift
//  
//
//  Created by Théodore Roos on 2022-09-12.
//

import Foundation
import Combine
import VSFoundation

final class PutUserService: DataFetchingManager {
  func call(with parameters: PutUserParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self)
  }
}

final class GetUserService: DataFetchingManager {
  func call(with parameters: GetUserParameters) -> AnyPublisher<[String:String], Error> {
    execute(parameters, errorType: Error.self)
  }
}

final class DeleteUserService: DataFetchingManager {
  func call(with parameters: DeleteUserParameters) -> AnyPublisher<Void, Error> {
    executeEmptyBody(parameters, errorType: Error.self)
  }
}

struct VPSProfileDto: Codable {
  let vpsProfile: String
}

struct TT2UserDto: Codable {
  public var id: String?
  public var userId: String?
  public var height: String?
  public var name: String?
  public var age: String?
  public var gender: String?
  public var route: String?
  public var comments: String?
  public var activity: String?
  public var deviceName: String?
}

extension TT2UserDto {
  var asTT2User: TT2User {
    let user = TT2User()
    user.id = id
    user.userId = userId
    if let height = height {
      user.height = Float(height)
    }
    user.name = name
    user.age = age
    user.gender = gender
    user.route = route
    user.comments = comments
    user.activity = activity
    user.deviceName = deviceName
    return user
  }
}
