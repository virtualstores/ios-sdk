//
// PositionObject
// VSTT2
//
// Created by Hripsime on 2022-01-18.
// Copyright Virtual Stores - 2021

enum PointStatus: String {
    case pending
    case inProgress
    case complete
    case fail
}

final class PositionObject: IPersistenceModel {
    var retainOriginalIndex: Bool = false
    var index: String?
    
    convenience init(index: String) {
        self.init()
        self.index = index
    }
    
    var key: String?
    var xPosition: Double?
    var yPosition: Double?
    var timeStamp: String?
    var status: String?
}
