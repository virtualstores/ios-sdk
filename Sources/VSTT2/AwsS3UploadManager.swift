//
//  AwsS3UploadManager.swift
//  ios-sdk
//
//  Created by Théodore Roos on 2022-03-22.
//  Copyright © 2020 Virtual Stores. All rights reserved.
//

import Foundation
import AWSS3
import VSFoundation

public enum AWSS3Keys: String {
  case dataAnalyze = "data-analyze/"
  case iosOfficeStepData = "ios-office-step-data/"
}

public protocol AwsS3UploadManagerDelegate {
  var id: String { get }
  func uploadSucceded()
}

final class AWSRecordObject: IPersistenceModel {
  var retainOriginalIndex = false
  var index: String?

  convenience init(index: String) {
    self.init()
    self.index = index
  }

  var identifier: String?
  var data: String?
  var date: String?
  var folderName: String?
  var status: String = Status.pending.rawValue

  enum Status: String {
    case pending = "pending"
    case inProgress = "inProgress"
    case failed = "failed"
    case succeded = "succeded"
  }
}

public class AWSS3UploadManager {
  @Inject var persistence: Persistence

  private static let MAX_TRIES = 20

  private func insert(identifier: String, data: String, date: String) {
    var recording = AWSRecordObject()
    recording.identifier = identifier
    recording.data = data
    recording.date = date

    do {
      try persistence.save(&recording)
    } catch {
      Logger(verbosity: .critical).log(message: "Failed to save recordObject: \(error.localizedDescription)")
    }
  }

  func prepareDataToSend(identifier: String, data: String, date: Date) {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HHmmss"
    let timedIdentifier = identifier + timeFormatter.string(from: date)
    insert(identifier: identifier, data: data, date: timedIdentifier)
  }

  func addAditionalData(identifier: String, fileName: String, data: String) {
    guard let object = getAllRecordedObject().first(where: { $0.identifier == identifier }), let date = object.date else { return }
    insert(identifier: fileName, data: data, date: date)
  }

  func sendCollectedDataToS3(status: AWSRecordObject.Status = .pending, folderName: String = "") {
    let arr = getAllRecordedObject().filter { $0.status == status.rawValue }
    arr.forEach { (object) in
      if let id = object.identifier, let convertedData = object.data?.data(using: .utf8) {
        self.sendToS3(AWSS3Key: .dataAnalyze, key: object.folderName ?? folderName, identifier: id, data: convertedData)
        object.folderName = folderName
        self.updateStatus(object: object, status: .inProgress)
      }
    }
  }

  func retryFailed() {
    sendCollectedDataToS3(status: .failed)
  }

  func retry(_ numberOfTimes: Int = 0) {
    DispatchQueue.global(qos: .background).async {
      sleep(self.getWaitTimeExp(retryCount: numberOfTimes))
      if numberOfTimes < AWSS3UploadManager.MAX_TRIES {


        self.retry(numberOfTimes + 1)
      } else {
        self.retry()
      }
    }
  }

  private func getWaitTimeExp(retryCount: Int) -> UInt32 {
    if retryCount == 0 {
      return 0
    }
    let waitTime = pow(2, retryCount)

    return UInt32(truncating: waitTime as NSNumber)
  }

  private func getAllRecordedObject() -> [AWSRecordObject] {
    persistence.get(arrayOf: AWSRecordObject.self)
  }

  private func updateRecordsAfter(uploadingFailed: Bool) {
    let arr = getAllRecordedObject()
    let filteredArr = arr.filter { $0.status == AWSRecordObject.Status.inProgress.rawValue }
    self.updateStatus(objects: filteredArr, status: uploadingFailed ? .failed : .succeded)
  }

  private func updateStatus(object: AWSRecordObject, status: AWSRecordObject.Status? = nil) {
    var editableObject: AWSRecordObject
    editableObject = object
    editableObject.status = status?.rawValue ?? object.status
    do {
      try persistence.save(&editableObject)
    } catch {
      Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                          message: "Update Points SQLite error")
    }

    guard let status = status else { return }
    switch status {
    case .pending: break
    case .inProgress: break
    case .failed: self.retryFailed()
    case .succeded: self.removeRecordedObject()
    }
  }

  private func updateStatus(objects: [AWSRecordObject], status: AWSRecordObject.Status) {
    objects.forEach { (object) in
      self.updateStatus(object: object, status: status)
    }
  }

  private func removeRecordedObject() {
    let arr = getAllRecordedObject()
    let filteredPositions = arr.filter { $0.status == AWSRecordObject.Status.succeded.rawValue }
    for object in filteredPositions {
      do {
        try persistence.delete(object)
      } catch {
        Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                            message: "Remove Points After Uploading SQLite error")
      }
    }
  }

  private func sendToS3(AWSS3Key: AWSS3Keys, key: String, identifier: String, data: Data) {
    let splitIdentifier = identifier.split(separator: ".")
    let strippedIdentifier = splitIdentifier[0].components(separatedBy: CharacterSet.decimalDigits).joined()
    var fileExtension = ".json"
    if splitIdentifier.count > 1 {
      fileExtension = "." + String(splitIdentifier[splitIdentifier.capacity - 1])
    }
    let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
    getPreSignedURLRequest.bucket = "product-information-storage"
    getPreSignedURLRequest.key = AWSS3Key.rawValue + key + strippedIdentifier + fileExtension
    getPreSignedURLRequest.httpMethod = .PUT
    getPreSignedURLRequest.expires = Date(timeIntervalSinceNow: 3600)

    //Important: set contentType for a PUT request.
    let fileContentTypeStr = "text/plain"
    getPreSignedURLRequest.contentType = fileContentTypeStr
    AWSS3PreSignedURLBuilder.default().getPreSignedURL(getPreSignedURLRequest).continueWith { (task:AWSTask<NSURL>) -> Any? in
      if let error = task.error as NSError? {
        Logger(verbosity: .critical).log(message: "Uploading error: \(error.localizedDescription)")
        self.updateRecordsAfter(uploadingFailed: true)
        return nil
      }
      
      let presignedURL = task.result
      var request = URLRequest(url: presignedURL! as URL)
      request.cachePolicy = .reloadIgnoringLocalCacheData
      request.httpMethod = "PUT"
      request.setValue(fileContentTypeStr, forHTTPHeaderField: "Content-Type")
      URLSession.shared.uploadTask(with: request, from: data) { (responseData, response, error) in
        if let error = error {
          Logger(verbosity: .critical).log(message: "Failed to upload \(identifier), trying again: \(error.localizedDescription)")
          self.updateRecordsAfter(uploadingFailed: true)
        } else {
          Logger(verbosity: .info).log(message: "Successfully uploaded \(identifier) to S3")
          self.updateRecordsAfter(uploadingFailed: false)
        }
      }.resume()
      return nil
    }
  }
}
