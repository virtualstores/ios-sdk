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
import Combine

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

  var getAllRecordedObject: [AWSRecordObject]  { persistence.get(arrayOf: AWSRecordObject.self) }

  var dataUploadedPublisher: CurrentValueSubject<Bool, Never> = .init(false)

  private static let MAX_TRIES = 20

  private var serialDispatch = DispatchQueue(label: "AWSS3UploadManagerSerial")

  init() {
    let region: AWSRegionType = .EUNorth1
    let provider = AWSCognitoCredentialsProvider(regionType: region, identityPoolId: "eu-north-1:33816793-1fcf-4333-9952-bd6327a65cdf")
    AWSServiceManager.default().defaultServiceConfiguration = AWSServiceConfiguration(region: region, credentialsProvider: provider)
    removeRecordedObject(where: .folderIsMissing)
    sendCollectedDataToS3(objects: getAllRecordedObject)
  }

  private func insert(identifier: String, data: String, date: String) {
    print("Insert", identifier)
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
    guard let object = getAllRecordedObject.first(where: { $0.identifier == identifier }), let date = object.date else { return }
    insert(identifier: fileName, data: data, date: date)
  }

  func sendCollectedDataToS3(status: AWSRecordObject.Status = .pending, folderName: String? = nil) {
    let objects = getAllRecordedObject
    var arr = objects.filter { $0.status == status.rawValue }
    if status != .failed {
      arr.append(contentsOf: objects.filter { $0.status == AWSRecordObject.Status.failed.rawValue })
    }
    sendCollectedDataToS3(objects: arr, folderName: folderName)
  }

  func sendCollectedDataToS3(objects: [AWSRecordObject], folderName: String? = nil) {
    objects.forEach { (object) in
      if folderName != nil {
        object.folderName = folderName
      }
      retry { self.sendToS3(AWSS3Key: .dataAnalyze, object: object) }
      updateStatus(object: object, status: .inProgress)
    }
  }

  func retryFailed() {
    sendCollectedDataToS3(status: .failed)
  }

  typealias Async = (_ success: @escaping (_ identifier: String, _ key: String) -> Void, _ failure: @escaping (_ identifier: String, _ key: String, _ error: Error) -> Void) -> Void
  func retry(_ numberOfTimes: Int = 0, task: @escaping () -> Async?) {
    guard let asyncTask = task() else { return }
    serialDispatch.asyncAfter(deadline: .now() + getWaitTimeExp(retryCount: numberOfTimes)) { [self] in
      asyncTask ({ (identifier, key) in
        self.updateRecordsAfter(uploadingFailed: false, identifier: identifier, key: key)
        if self.getAllRecordedObject.filter({ $0.status == AWSRecordObject.Status.inProgress.rawValue }).count == 0 {
          DispatchQueue.main.async { self.dataUploadedPublisher.send(true) }
        }
      }, { [self] (identifier, key, error) in
        Logger(verbosity: .silent).log(message: "Failure uploading file: \(error)")
        if numberOfTimes < AWSS3UploadManager.MAX_TRIES {
          retry(numberOfTimes + 1, task: task)
        } else {
          self.updateRecordsAfter(uploadingFailed: true, identifier: identifier, key: key)
        }
      })
    }
  }

  private func getWaitTimeExp(retryCount: Int) -> Double {
    guard retryCount > 0 else { return 0 }
    let waitTime = Double(truncating: pow(1.4, retryCount) as NSNumber)
    return min(waitTime, 2 * 60)
  }

  private func updateRecordsAfter(uploadingFailed: Bool, identifier: String, key: String) {
    guard let object = getAllRecordedObject.filter({ $0.status == AWSRecordObject.Status.inProgress.rawValue }).first(where: { $0.identifier == identifier && key.contains($0.folderName ?? "") }) else { return }
    updateStatus(object: object, status: uploadingFailed ? .failed : .succeded)
  }

  private func updateStatus(object: AWSRecordObject, status: AWSRecordObject.Status) {
    var editableObject = object
    editableObject.status = status.rawValue
    do {
      try persistence.save(&editableObject)
    } catch {
      Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                          message: "Update Points SQLite error")
    }

    switch status {
    case .pending: break
    case .inProgress: break
    case .failed: retryFailed()
    case .succeded: removeRecordedObject(where: .status(.succeded))
    }
  }

  private func updateStatus(objects: [AWSRecordObject], status: AWSRecordObject.Status) {
    objects.forEach { (object) in
      updateStatus(object: object, status: status)
    }
  }

  enum RemoveRecordedObjectOptions {
    case all
    case folderIsMissing
    case identifier(String)
    case status(AWSRecordObject.Status)
  }

  func removeRecordedObject(where option: RemoveRecordedObjectOptions) {
    let objects: [AWSRecordObject]
    switch option {
    case .all: objects = getAllRecordedObject
    case .folderIsMissing: objects = getAllRecordedObject.filter { $0.folderName == nil }
    case .identifier(let identifier): objects = getAllRecordedObject.filter { $0.identifier == identifier }
    case .status(let status): objects = getAllRecordedObject.filter { $0.status == status.rawValue }
    }

    objects.forEach { (object) in
      do {
        try persistence.delete(object)
      } catch {
        Logger(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                            message: "Remove Points After Uploading SQLite error")
      }
    }
  }

  private func sendToS3(AWSS3Key: AWSS3Keys, object: AWSRecordObject) -> Async? {
    guard let id = object.identifier, let folderName = object.folderName, let convertedData = object.data?.data(using: .utf8) else { return nil }
    return sendToS3(AWSS3Key: AWSS3Key, key: folderName, identifier: id, data: convertedData)
  }

  private func sendToS3(AWSS3Key: AWSS3Keys, key: String, identifier: String, data: Data) -> Async {
    return { (success, failure) in
      let splitIdentifier = identifier.split(separator: ".")
      let strippedIdentifier = splitIdentifier[0]
      var fileExtension = ".json"
      if splitIdentifier.count > 1 {
        fileExtension = "." + String(splitIdentifier[splitIdentifier.capacity - 1])
      }
      let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
      getPreSignedURLRequest.bucket = "virtualstores-public-files"
      getPreSignedURLRequest.key = AWSS3Key.rawValue + key + strippedIdentifier + fileExtension
      getPreSignedURLRequest.httpMethod = .PUT
      getPreSignedURLRequest.expires = Date(timeIntervalSinceNow: 3600)

      //Important: set contentType for a PUT request.
      let fileContentTypeStr = "application/json"
      getPreSignedURLRequest.contentType = fileContentTypeStr
      AWSS3PreSignedURLBuilder.default().getPreSignedURL(getPreSignedURLRequest).continueWith { (task:AWSTask<NSURL>) -> Any? in
        if let error = task.error as NSError? {
          /*Logger(verbosity: .error)*/Logger().log(message: "Uploading error: \(error.localizedDescription)")
          self.updateRecordsAfter(uploadingFailed: true, identifier: identifier, key: key)
          failure(identifier, key, error)
          return nil
        }

        let presignedURL = task.result
        var request = URLRequest(url: presignedURL! as URL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "PUT"
        request.setValue(fileContentTypeStr, forHTTPHeaderField: "Content-Type")
        URLSession.shared.uploadTask(with: request, from: data) { (responseData, response, error) in
          if let error = error {
            /*Logger(verbosity: .error)*/Logger(verbosity: .error).log(message: "Failed to upload \(identifier), trying again: \(error.localizedDescription)")
            failure(identifier, key, error)
          } else {
            /*Logger(verbosity: .info)*/Logger(verbosity: .info).log(message: "Successfully uploaded \(identifier) to S3")
            success(identifier, key)
          }
        }.resume()
        return nil
      }
    }
  }
}
