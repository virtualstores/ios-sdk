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
    var positionObjects: [PositionObject] { persistence.get(arrayOf: PositionObject.self) }

    func insert(id: String, xPosition: Double, yPosition: Double, time: String, uploadStatus: PointStatus, visitId: Int64) {
        var object = PositionObject()
        object.key = id
        object.xPosition = xPosition
        object.yPosition = yPosition
        object.timeStamp = time
        object.status = uploadStatus.rawValue
        object.visitId = visitId

        do {
            try persistence.save(&object)
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Save Point Object SQLite error")
        }
    }

    /// Will return filtered points
    func getPoints() -> [Int64: [String: [RecordedPosition]]] {
        var pointsList: [Int64: [String: [RecordedPosition]]] = [:]
        let positions = positionObjects.filter { $0.status == PointStatus.pending.rawValue || $0.status == PointStatus.fail.rawValue }
        
        updateObjectStatus(objects: positions, status: .inProgress)
        
        positions.forEach { (object) in
            if let xPosition = object.xPosition, let yPosition = object.yPosition, let timeStamp = object.timeStamp, let key = object.key, let id = object.visitId {
                let recordedPosition = RecordedPosition(xPosition: xPosition, yPosition: yPosition, timeStamp: timeStamp)
                if pointsList[id] == nil {
                    pointsList[id] = [:]
                }
                if pointsList[id]?[key] == nil {
                    pointsList[id]?[key] = []
                }
                pointsList[id]?[key]?.append(recordedPosition)
            }
        }
        
        return pointsList
    }
    
    /// Will return all points
    func getAllPoints() -> [Int64: [String: [RecordedPosition]]] {
        var pointsList: [Int64: [String: [RecordedPosition]]] = [:]
        positionObjects.forEach { (object) in
            if let xPosition = object.xPosition, let yPosition = object.yPosition, let timeStamp = object.timeStamp, let key = object.key, let id = object.visitId {
                let recordedPosition = RecordedPosition(xPosition: xPosition, yPosition: yPosition, timeStamp: timeStamp)
                if pointsList[id] == nil {
                    pointsList[id] = [:]
                }
                if pointsList[id]?[key] == nil {
                    pointsList[id]?[key] = []
                }
                pointsList[id]?[key]?.append(recordedPosition)
            }
        }
        
        return pointsList
    }

    func updatePointsAfter(uploadingFailed: Bool) {
        let positions = positionObjects.filter { $0.status == PointStatus.inProgress.rawValue }
        self.updateObjectStatus(objects: positions, status: uploadingFailed ? PointStatus.fail : PointStatus.complete)
    }

    func removePoints() {
        let positions = positionObjects.filter { $0.status == PointStatus.complete.rawValue }
        positions.forEach { (object) in
            do {
                try persistence.delete(object)
            } catch {
                Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                    message: "Remove Points After Uploading SQLite error")
            }
        }
    }
    
    func removeAllPoints() {
        positionObjects.forEach { (object) in
            do {
                try persistence.delete(object)
            } catch {
                Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                    message: "Remove All Points After Uploading SQLite error")
            }
        }
    }

    private func updateObjectStatus(objects: [PositionObject], status: PointStatus) {
        objects.forEach { (object) in
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
