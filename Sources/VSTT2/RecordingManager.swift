//
//  Recording.swift
//  
//
//  Created by Théodore Roos on 2022-08-29.
//

import Foundation
import VSFoundation
import Combine

public protocol IRecordingManager {
  var dataUploadedPublisher: CurrentValueSubject<Bool, Never> { get }
  var recordedObjects: [AWSRecordedObject] { get }

  func sendData()
}

class RecordingManager: IRecordingManager {
  @Inject var navigation: Navigation
  @Inject var uploader: AWSS3UploadManager

  var sendDataPublisher: CurrentValueSubject<Void, Never> = .init(())
  var dataUploadedPublisher: CurrentValueSubject<Bool, Never> = .init(false)

  var recordedObjects: [AWSRecordedObject] { uploader.getAllRecordedObjects }

  private var cancellable = Set<AnyCancellable>()

  init() {
    bindPublishers()
  }

  deinit {
    cancellable.removeAll()
  }

  func bindPublishers() {
    uploader.dataUploadedPublisher
      .sink { [weak self] in self?.dataUploadedPublisher.send($0) }
      .store(in: &cancellable)
  }

  func start() {
    navigation.startRecording()
  }

  func stop() {
    navigation.stopRecording()
  }

  func sendData() {
    sendDataPublisher.send()
  }
}

public struct RecordingMetaData: Codable {
  public var userId: String?
  public var height: Float?
  public var name: String?
  public var age: String?
  public var gender: String?
  public var route: String?
  public var comments: String?
  public var activity: String?
  public var deviceName: String?

  public init(userId: String? = nil, height: Float? = nil, name: String? = nil, age: String? = nil, gender: String? = nil, route: String? = nil, comments: String? = nil, activity: String? = nil, deviceName: String? = nil) {
    self.userId = userId
    self.height = height
    self.name = name
    self.age = age
    self.gender = gender
    self.route = route
    self.comments = comments
    self.activity = activity
    self.deviceName = deviceName
  }
}
