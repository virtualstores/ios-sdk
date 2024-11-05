//
// PositionUploadWorker
// VSTT2
//
// Created by Hripsime on 2022-01-18
// Copyright Virtual Stores - 2021

import Foundation
import UIKit
import VSFoundation

final class PositionUploadWorker {
    @Inject var persistence: Persistence
    @Inject var activeStore: GetActiveStoreUseCase
    var positionObjects: [PositionObject] { persistence.get(arrayOf: PositionObject.self) }

    func insert(id: String, xPosition: Double, yPosition: Double, time: String, uploadStatus: PointStatus, visitId: Int64) {
        var object = PositionObject()
        object.key = id
        object.xPosition = xPosition
        object.yPosition = yPosition
        object.timestamp = time
        object.status = uploadStatus.rawValue
        object.visitId = visitId

        do {
            try persistence.save(&object)
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Save Point Object SQLite error")
        }
    }

    var positionObjects2: [Int64: [String: [RecordedPosition]]] = [:]
    func insert(floorId: Int64, position: RecordedPosition, visitId: Int64) {
      positionObjects2[visitId, default: [:]][floorId.description, default: []].append(position)
      if positionObjects2[visitId]?[floorId.description]?.count ?? 0 > 100 {
        saveObjects()
      }
    }

    func saveObjects() {
      positionObjects2.forEach { (key, value) in
        var object = UploadPositionsPersistence()
        object.serverConnection = activeStore.invoke().statServerConnection
        object.visitId = key
        object.requestId = UUID().uuidString.uppercased()
        object.positionGrps = value
        object.status = PointStatus.pending.rawValue
        do {
          try persistence.save(&object)
          positionObjects2.removeValue(forKey: key)
        } catch {
          Logger(verbosity: .silent).log(
            tag: Logger.createTag(fileName: #file, functionName: #function),
            message: "Save Point Object SQLite error")
        }
      }
    }

    func getParameters() -> [UploadPositionsParameters] {
      let objects = persistence
        .get(arrayOf: UploadPositionsPersistence.self)
        .filter { $0.status == PointStatus.pending.rawValue || $0.status == PointStatus.fail.rawValue }

      updateStatus(for: objects, status: .inProgress)
      return objects
        .map { $0.asParameters }
        .compactMap { $0 }
    }

    func updateObjectsAfterUpload(didFail: Bool) {
      let objects = persistence
        .get(arrayOf: UploadPositionsPersistence.self)
        .filter { $0.status == PointStatus.inProgress.rawValue }
      updateStatus(for: objects, status: didFail ? .fail : .complete)
    }

    func removeCompletedObjects() {
      let objects = persistence
        .get(arrayOf: UploadPositionsPersistence.self)
        .filter { $0.status == PointStatus.complete.rawValue }
      objects.forEach { (object) in
        do {
          try persistence.delete(object)
        } catch {
          Logger(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                         message: "Remove Points After Uploading SQLite error")
        }
      }
    }

    private func updateStatus(for objects: [UploadPositionsPersistence], status: PointStatus) {
      objects.forEach { (object) in
        var editableObject: UploadPositionsPersistence
        editableObject = object
        editableObject.status = status.rawValue

        do {
          try persistence.save(&editableObject)
        } catch {
          Logger(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                         message: "Update Points SQLite error")
        }
      }
    }

    /// Will return filtered points
    func getPoints() -> [Int64: [String: [RecordedPosition]]] {
        var pointsList: [Int64: [String: [RecordedPosition]]] = [:]
        let positions = positionObjects.filter { $0.status == PointStatus.pending.rawValue || $0.status == PointStatus.fail.rawValue }
        
        updateObjectStatus(objects: positions, status: .inProgress)
        
        positions.forEach { (object) in
            if let xPosition = object.xPosition, let yPosition = object.yPosition, let timestamp = object.timestamp, let key = object.key, let id = object.visitId {
                let recordedPosition = RecordedPosition(xPosition: xPosition, yPosition: yPosition, timestamp: timestamp)
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
            if let xPosition = object.xPosition, let yPosition = object.yPosition, let timestamp = object.timestamp, let key = object.key, let id = object.visitId {
                let recordedPosition = RecordedPosition(xPosition: xPosition, yPosition: yPosition, timestamp: timestamp)
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
