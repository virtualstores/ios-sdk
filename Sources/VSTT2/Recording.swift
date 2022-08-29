//
//  Recording.swift
//  
//
//  Created by Théodore Roos on 2022-08-29.
//

import Foundation
import VSFoundation
import Combine

public protocol IRecording {
  var dataUploadedPublisher: CurrentValueSubject<Bool, Never> { get }

  /**
   * Starts debug recording.
   * Resets the recording if already recording.
   */
  func start()

  /**
   * Stops debug recording and uploads.
   * Recommended to use wifi.
   */
  func stop()

  func sendData()
}

class Recording: IRecording {
  @Inject var navigation: Navigation
  @Inject var uploader: AWSS3UploadManager

  var sendDataPublisher: CurrentValueSubject<Void, Never> = .init(())
  var dataUploadedPublisher: CurrentValueSubject<Bool, Never> = .init(false)

  private var cancellable = Set<AnyCancellable>()

  init() {
    bindPublishers()
  }

  deinit {
    cancellable.removeAll()
  }

  func bindPublishers() {
    uploader.dataUploadedPublisher
      .sink { (value) in
        self.dataUploadedPublisher.send(value)
      }.store(in: &cancellable)
  }

  func start() {
    navigation.startRecording()
  }

  func stop() {
    navigation.stopRecording()
  }

  func sendData() {
    sendDataPublisher.send(())
  }
}
