//
// PositionUploadWorker
// VSTT2
//
// Created by Hripsime on 2022-01-18
// Copyright Virtual Stores - 2021

import Foundation
import SQLite
import UIKit
import VSFoundation

final class PositionUploadWorker {
    @Inject var persistence: Persistence
    
    func insert(id: String, xPosition: Double, yPosition: Double, time: String, uploadStatus: PointStatus) {
        var object = PositionObject()
        object.key = id
        object.xPosition = xPosition
        object.yPosition = yPosition
        object.timeStamp = time
        object.status = uploadStatus.rawValue
        
        do {
            try persistence.save(&object)
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Save Point Object SQLite error")
        }
    }
    
    func getPoints() throws -> [String: [RecordedPosition]]? {
        var pointsList: [String: [RecordedPosition]] = [:]
            let positions = persistence.get(arrayOf: PositionObject.self)
            let filteredPositions = positions.filter{ $0.status == PointStatus.pending.rawValue || $0.status == PointStatus.fail.rawValue }
            
        self.updateObjectStatus(objects: filteredPositions, status: PointStatus.inProgress)

        for object in filteredPositions {
            if let xPosition = object.xPosition, let yPosition = object.yPosition, let timeStamp = object.timeStamp, let key = object.key {
                let recordedPosition = RecordedPosition(xPosition: xPosition, yPosition: yPosition, timeStamp: timeStamp)
                if pointsList[key] == nil {
                    pointsList[key] = []
                }
                pointsList[key]?.append(recordedPosition)
            }
        }

        return pointsList
    }
    
    func updatePointsAfter(uploadingFailed: Bool) {
        let positions = persistence.get(arrayOf: PositionObject.self)
        let filteredPositions = positions.filter{ $0.status == PointStatus.inProgress.rawValue }
        
        self.updateObjectStatus(objects: filteredPositions, status: uploadingFailed ? PointStatus.fail : PointStatus.complete)
    }
    
    func removePoints() {
        let positions = persistence.get(arrayOf: PositionObject.self)
        let filteredPositions = positions.filter{ $0.status == PointStatus.complete.rawValue }
        
        for object in filteredPositions {
            do {
                try persistence.delete(object)
            } catch {
                Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                    message: "Remove Points After Uploading SQLite error")
            }
        }
    }
    
    private func updateObjectStatus(objects: [PositionObject], status: PointStatus) {
        for object in objects {
            var editableObject: PositionObject
            editableObject = object
            editableObject.status = status.rawValue
            
            do {
                try persistence.save(&editableObject)
            } catch {
                Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                    message: "Update Points SQLite error")
            }
        }
    }
}
