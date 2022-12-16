//
// TT2User
// ITT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation

final public class TT2User: IPersistenceModel {
    public var retainOriginalIndex = false
    public var index: String?

    public init() { }
    
    func setup(id: String?, userId: String?, height: Float?, name: String?, age: String?, gender: String?) {
        self.id = id
        self.userId = userId
        self.height = height
        self.name = name
        self.age = age
        self.gender = gender
    }
    
    convenience init(index: String) {
        self.init()
        self.index = index
    }

    public var id: String?
    public var userId: String?
    public var height: Float?
    public var name: String?
    public var age: String?
    public var gender: String?
    public var route: String?
    public var comments: String?
    public var activity: String?
    public var deviceName: String?
    var vpsProfile: [String:String]?
}
