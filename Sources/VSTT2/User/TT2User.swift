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

    public init() {
        self.alpha = []
        self.beta = []
        self.y = []
    }
    
    convenience init(index: String) {
        self.init()
        self.index = index
    }

    public var id: String?
    public var userId: String?
    public var userHeight: Float?
    public var name: String?
    public var age: String?
    public var gender: String?
    public var speedRegressionIntercept: Float?
    public var speedRegressionSlope: Float?
    public var alpha: [Float]?
    public var beta: [Float]?
    public var y: [Float]?
    public var noScanML: String?
}

