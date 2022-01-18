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

enum PointStatus: String {
    case panding
    case inProgress
    case complete
    case fail
}

final class PositionUploadWorker {
    // DB Info
    var db: Connection?

    let points = Table("recordingInfo")
    let key = Expression<String>("key")
    let xPosition = Expression<Double>("xPosition")
    let yPosition = Expression<Double>("yPosition")
    let timeStamp = Expression<String>("timeStamp")
    let status = Expression<String>("status")

    public init() {
        dbSetup()
    }

    func dbSetup() {
        let databaseFileName = "db.sqlite3"
        let databaseFilePath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(databaseFileName)"
        db = try! Connection(databaseFilePath)

        guard let db = db else { return }

        try! db.run(points.create(ifNotExists: true) { t in
            t.column(key)
            t.column(xPosition)
            t.column(yPosition)
            t.column(timeStamp)
            t.column(status)
        })
    }

    func insert(id: String, x: Double, y: Double, time: String, uploadStatus: PointStatus) {
        do {
            let rowid = try db!.run(points.insert(key <- id, xPosition <- x, yPosition <- y, timeStamp <- time, status <- uploadStatus.rawValue))
            Logger.init(verbosity: .debug).log(message: "Row inserted successfully id: \(rowid)")
        } catch {
            Logger.init(verbosity: .debug).log(message: "insertion failed: \(error)")
        }
    }

    func getPoints() throws -> [String: [RecordedPosition]]? {
        guard let db = db else { return nil }
        var pointsList: [String: [RecordedPosition]] = [:]

        let alice = points.filter(status == PointStatus.panding.rawValue || status == PointStatus.fail.rawValue)

        try db.run(alice.update(status <- PointStatus.inProgress.rawValue))
        for point in try db.prepare(points) {
            let recordedPosition = RecordedPosition(xPosition: point[xPosition], yPosition: point[yPosition], timeStamp: point[timeStamp])
            let id = point[key]
            if pointsList[id] == nil {
                pointsList[id] = []
            }
            pointsList[id]?.append(recordedPosition)
        }

        return pointsList
    }

    func updatePointsAfterUploading() {
        guard let db = db else { return }

        let alice = points.filter(status == PointStatus.inProgress.rawValue)
        do {
            try db.run(alice.update(status <- PointStatus.complete.rawValue))
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Update Points After Uploading SQLite error")
        }
    }

    func updatePointsAfterUploadingFail() {
        guard let db = db else { return }

        let alice = points.filter(status == PointStatus.inProgress.rawValue)
        do {
            try db.run(alice.update(status <- PointStatus.fail.rawValue))
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Update Points After Uploading fail SQLite error")
        }
    }

    func removePoints() {
        guard let db = db else { return }

        let alice = points.filter(status == PointStatus.complete.rawValue)
        do {
            try db.run(alice.delete())
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "RemovePoints from SQLite error")
        }
    }
}
