//
// UserSettings
// ITT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import VSFoundation

public class UserSettings: IUserSettings {
    @Inject var persistence: Persistence

    public func setUser(user: User) {
        var object = user
        do {
         //   try persistence.save(&object)
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Save User Object SQLite error")
        }
    }
    
    public func getUser(userId: String) -> User? {
        return nil
//        let users = persistence.get(arrayOf: User.self)
//        let user = users.first(where: { $0.userId == userId })
//
//        return user
    }
    
    public func getLastUser() -> User? {
       // let users = persistence.get(arrayOf: User.self)
        
        return nil
       // return users.last ?? nil
    }
    
    public func clearAllUserSettings() { }
    
    public func clearUser(userId: String) {
      //  let users = persistence.get(arrayOf: User.self)
       // guard let user = users.first(where: { $0.userId == userId }) else { return }
        
        do {
          //  try persistence.delete(user)
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Remove User error")
        }
    }
}
