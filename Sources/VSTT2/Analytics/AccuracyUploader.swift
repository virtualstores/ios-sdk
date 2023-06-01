//
//  AccuracyUploader.swift
//  
//
//  Created by Théodore Roos on 2022-03-22.
//

import Combine
import Foundation
import UIKit
import VSFoundation
import VSPositionKit
import vps

class AccuracyUploader {
  @Inject var analytics: TT2AnalyticsManager
  @Inject var syncEventsService: UploadSyncEventsService
  @Inject var floorManager: VSTT2FloorManager
  @Inject var persistence: Persistence

  let store: Store
  let connection: ServerConnection
  let client: Client
  let converter: ICoordinateConverter

  var stepEventUploader: StepEventUploader? { analytics.stepEventUploader }
  var config: EnvironmentConfig? { analytics.config }

  var numberOfRescueModes: Int64 = 0

  private var cancellable = Set<AnyCancellable>()

  public enum Errors: Error {
    case uploadFailure(HTTPURLResponse)
  }

  init(store: Store, connection: ServerConnection, client: Client, converter: ICoordinateConverter) {
    self.store = store
    self.connection = connection
    self.client = client
    self.converter = converter
  }

  deinit {
    cancellable.removeAll()
  }

  private func upload(id: String, preScanLocation: CGPoint, position: ItemPosition, errorHandler: @escaping (Error) -> Void) {
    guard
      let serverAddress = connection.serverAddress,
      let clientName = client.name,
      //let positionKitVersion = Bundle(identifier: "org.cocoapods.PositionKit")?.infoDictionary?["CFBundleShortVersionString"] as? String,
      let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
      let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    else { return }
    var urlComponents = URLComponents()

    // Ternary operator
    let offset = position.offset
    let dx = abs(offset.dx) > 0.02 ? offset.dx : 0.0
    let dy = abs(offset.dy) > 0.02 ? offset.dy : 0.0

    let systemName = UIDevice.current.systemName
    let systemVersion = UIDevice.current.systemVersion
    let modelName = UIDevice.current.modelName

    urlComponents.scheme = "https"
    urlComponents.host = "docs.google.com"
    #if DEBUG
    urlComponents.path = "/forms/d/e/1FAIpQLScPK5ecdReEe-1hdMMOWkCgp1H8n54IbSH4CrxjcSaCSV_D-Q/formResponse"
    #else
    urlComponents.path = "/forms/d/e/1FAIpQLSe0Db_cq-rGUWGVVYV0b4xXLDI36ou19SbOX4kWucM-Ai6D_A/formResponse"
    #endif

    urlComponents.queryItems = [
      URLQueryItem(entry: .sessionId, value: id),
      URLQueryItem(entry: .articleId, value: position.identifier),
      URLQueryItem(entry: .preScanLocationX, value: "\(preScanLocation.x)"),
      URLQueryItem(entry: .preScanLocationY, value: "\(preScanLocation.y)"),
      URLQueryItem(entry: .offsetX, value: "\(dx)"),
      URLQueryItem(entry: .offsetY, value: "\(dy)"),
      URLQueryItem(entry: .scanLocationX, value: "\(position.point.x)"),
      URLQueryItem(entry: .scanLocationY, value: "\(position.point.y)"),
      URLQueryItem(entry: .appVersion, value: "\(appVersion) (\(buildNumber)), \(systemName) \(systemVersion), \(modelName)"),
      URLQueryItem(entry: .positionKitVersion, value: VPSConfig.shared.VPS_VERSION),//\(positionKitVersion)"),
      URLQueryItem(entry: .serverUrl, value: "\(serverAddress)"),
      URLQueryItem(entry: .clientId, value: "\(client.clientId), \(clientName)"),
      URLQueryItem(entry: .storeId, value: "\(store.id), \(store.name)"),
      URLQueryItem(name: "submit", value: "Submit")
    ]

    guard let url = urlComponents.url else { return }

//    print(url)
    URLSession.shared.dataTask(with: url) {(data, response, error) in
      DispatchQueue.main.async {
        if let response = response as? HTTPURLResponse {
          switch response.statusCode {
          case 200...299: break
          default: errorHandler(Errors.uploadFailure(response))
          }
        } else if let error = error {
          errorHandler(error)
        }
      }
    }.resume()
//    URLSession.shared.dataTaskPublisher(for: url)
//      .tryMap { element in
//        if let response = element.response as? HTTPURLResponse {
//          switch response.statusCode {
//          case 200...299: break
//          default: errorHandler(Errors.uploadFailure(response))
//          }
//        }
//      }//.mapError { errorHandler($0 as Error) }
  }

  func upload(syncEvent: AccuracySyncEvent.Event, isFloorSwap: Bool) {
    guard
      let visitId = analytics.visitId,
      let rtlsOptionsId = analytics.rtlsOptionId,
      let mapFence = floorManager.mapFence[rtlsOptionsId]
//      let mapFenceData = MapFenceFactory.getMapFenceData(fromMapFence: mapFence)
    else { return }
    let mapFenceData = MapFenceFactory.getMapFenceData(fromMapFence: mapFence)
    let identifier: String
    var didSync: Bool = true
    var point: CGPoint = .zero
    var pointWithOffset: CGPoint = .zero
    var preScanLocation: CGPoint?
    var offset: CGVector?

    var tags:[String:String]
    switch syncEvent {
    case .syncEvent(let event):
      let position = event.itemPosition
      identifier = position.identifier
      point = position.point
      pointWithOffset = position.pointWithOffset
      preScanLocation = event.preSyncScanLocation
      offset = position.offset
      didSync = event.didSync
      upload(id: String(visitId), preScanLocation: event.preSyncScanLocation, position: position, errorHandler: { (error) in
        Logger(verbosity: .info).log(message: "AccuracyUploaderError: \(error.localizedDescription)")
      })
      tags = [
        "identifier": identifier,
        "isStartSync": String(false)
      ]
      if let shelfId = position.shelfId {
        tags["shelfId"] = String(shelfId)
      }
    case .syncEventMissingPosition(let event):
      identifier = event.identifier
      didSync = false
      tags = [
        "identifier": identifier,
        "isStartSync": String(false),
        "noItemPosition": String(true)
      ]
    case .syncEventMultipleItemPosition(let event):
      identifier = event.item.externalId
      didSync = false
      tags = [
        "identifier": identifier,
        "isStartSync": String(false),
        "multipleItemPosition": String(true)
      ]
    case .startLocationSyncEvent(let event):
      identifier = event.startScanLocation.code
      point = event.startScanLocation.point
      pointWithOffset = point
      tags = [
        "identifier": identifier,
        "isStartSync": String(true),
        "syncAngle": String(event.startScanLocation.direction)
      ]
    case .startSyncEvent(let event):
      let position = event.itemPosition
      identifier = position.identifier
      point = position.point
      pointWithOffset = position.pointWithOffset
      offset = position.offset
      didSync = event.didSync
      tags = [
        "identifier": identifier,
        "isStartSync": String(true),
        "syncAngle": String(event.startDirection)
      ]
      if let shelfId = position.shelfId {
        tags["shelfId"] = String(shelfId)
      }
    }

    let preScanLocationInPixels = preScanLocation?.fromMeterToPixel(converter: converter)
    let scanLocationInPixels = pointWithOffset.fromMeterToPixel(converter: converter)
    let isRightAisle = preScanLocation != nil ? mapFenceData.isRightAisle(p1: preScanLocationInPixels!, p2: scanLocationInPixels) : false

    //tags["isWifiResetSync"] = String(false)
    //if (tags["isWifiResetSync"]! as NSString).boolValue {
    //  tags["wifiResetSyncRadius"] = String(0)
    //}
    let distance: Double = stepEventUploader?.events.map { $0.distance }.sum() ?? 0.0
    let event = SyncEvent(
      rtlsOptionsId: rtlsOptionsId,
      identifier: identifier,
      isRightAisle: !isFloorSwap ? isRightAisle : false,
      isFloorSwap: isFloorSwap,
      didSync: didSync,
      rescueModeCountSinceLastSync: numberOfRescueModes,
      stepDataDistanceSinceLastSyncInMeters: distance,
      userToSyncPositionDistanceInMeters: (preScanLocation ?? point).distance(to: point),
      errorAngleInDegrees: 0,
      timestamp: Date(),
      userPositionInMeters: preScanLocation ?? .zero,
      syncPositionInMeters: point,
      syncPositionOffsetsInMeters: offset ?? .zero,
      tags: tags
    )
    let parameters = UploadSyncEventsParameters(
      config: config,
      visitId: visitId,
      requestId: UUID().uuidString.uppercased(),
      event: event
    )
    do {
      var persistence = parameters.asPersistence
      try self.persistence.save(&persistence)
      upload(parameters: parameters)
      stepEventUploader?.upload()
      numberOfRescueModes = 0
    } catch {
      Logger(verbosity: .error).log(message: "UploadSyncEventsParametersSaveError \(error)")
    }
  }

  func upload(parameters: UploadSyncEventsParameters) {
    syncEventsService
      .call(with: parameters)
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error):
          Logger(verbosity: .debug).log(message: "AccuracyUploaderError \(error)")
        }
      } receiveValue: { (_) in
        let persistence = parameters.asPersistence
        do {
          try self.persistence.delete(persistence)
        } catch {
          Logger(verbosity: .error).log(message: "UploadSyncEventsParametersDeleteError \(error)")
        }
      }.store(in: &cancellable)
  }

  func retryFailed() {
    let objects = getAllSyncEventObjects()
    objects.forEach { (object) in
      guard let parameters = object.asParameters else { return }
      upload(parameters: parameters)
    }
  }

  func getAllSyncEventObjects() -> [UploadSyncEventsPersistence] {
    persistence.get(arrayOf: UploadSyncEventsPersistence.self)
  }
}

extension URLQueryItem {
  enum EntryIDs: String {
    case sessionId = "entry.723772527"
    case articleId = "entry.234712389"
    case preScanLocationX = "entry.421535035"
    case preScanLocationY = "entry.1326043207"
    case offsetX = "entry.1258351828"
    case offsetY = "entry.708563230"
    case scanLocationX = "entry.832291956"
    case scanLocationY = "entry.1411294416"
    case appVersion = "entry.1892335868"
    case positionKitVersion = "entry.827959482"
    case serverUrl = "entry.548783748"
    case clientId = "entry.1270289197"
    case storeId = "entry.1258341166"
    case visitId = "entry.788993633"
    //    case combinedInfo = "entry.234712389"
  }

  init(entry: EntryIDs, value: String) {
    self.init(name: entry.rawValue, value: value)
  }
}

extension UploadSyncEventsParameters {
  var asPersistence: UploadSyncEventsPersistence {
    let event = UploadSyncEventsPersistence()
    event.apiKey = config?.centralServerConnection.apiKey
    event.serverAddress = config?.centralServerConnection.serverAddress
    event.mqttAddress = config?.centralServerConnection.mqttAddress
    event.storeId = config?.centralServerConnection.storeId

    event.visitId = visitId
    event.requestId = requestId

    event.rtlsOptionsId = self.event.rtlsOptionsId
    event.identifier = self.event.identifier
    event.isRightAisle = self.event.isRightAisle
    event.isFloorSwap = self.event.isFloorSwap
    event.didSync = self.event.didSync
    event.rescueModeCountSinceLastSync = self.event.rescueModeCountSinceLastSync
    event.stepDataDistanceSinceLastSyncInMeters = self.event.stepDataDistanceSinceLastSyncInMeters
    event.userToSyncPositionDistanceInMeters = self.event.userToSyncPositionDistanceInMeters
    event.errorAngleInDegrees = self.event.errorAngleInDegrees
    event.timestamp = self.event.timestamp
    event.userPositionInMeters = self.event.userPositionInMeters
    event.syncPositionInMeters = self.event.syncPositionInMeters
    event.syncPositionOffsetsInMeters = self.event.syncPositionOffsetsInMeters
    event.tags = self.event.tags
    return event
  }
}

extension UploadSyncEventsPersistence {
  var asParameters: UploadSyncEventsParameters? {
    guard
      let visitId = visitId,
      let requestId = requestId,
      let rtlsOptionsId = rtlsOptionsId,
      let identifier = identifier,
      let isRightAisle = isRightAisle,
      let isFloorSwap = isFloorSwap,
      let didSync = didSync,
      let rescueModeCountSinceLastSync = rescueModeCountSinceLastSync,
      let stepDataDistanceSinceLastSyncInMeters = stepDataDistanceSinceLastSyncInMeters,
      let userToSyncPositionDistanceInMeters = userToSyncPositionDistanceInMeters,
      let errorAngleInDegrees = errorAngleInDegrees,
      let timestamp = timestamp,
      let userPositionInMeters = userPositionInMeters,
      let syncPositionInMeters = syncPositionInMeters,
      let syncPositionOffsetsInMeters = syncPositionOffsetsInMeters,
      let tags = tags
    else { return nil }
    let config = EnvironmentConfig()
    config.centralServerConnection = ServerConnection(apiKey: apiKey, serverAddress: serverAddress, mqttAddress: mqttAddress, storeId: storeId)
    return UploadSyncEventsParameters(
      config: config,
      visitId: visitId,
      requestId: requestId,
      event: SyncEvent(
        rtlsOptionsId: rtlsOptionsId,
        identifier: identifier,
        isRightAisle: isRightAisle,
        isFloorSwap: isFloorSwap,
        didSync: didSync,
        rescueModeCountSinceLastSync: rescueModeCountSinceLastSync,
        stepDataDistanceSinceLastSyncInMeters: stepDataDistanceSinceLastSyncInMeters,
        userToSyncPositionDistanceInMeters: userToSyncPositionDistanceInMeters,
        errorAngleInDegrees: errorAngleInDegrees,
        timestamp: timestamp,
        userPositionInMeters: userPositionInMeters,
        syncPositionInMeters: syncPositionInMeters,
        syncPositionOffsetsInMeters: syncPositionOffsetsInMeters,
        tags: tags
      )
    )
  }
}

struct AccuracySyncEvent {
  enum Event {
    case syncEvent(SyncEvent)
    case syncEventMissingPosition(SyncEventMissingPosition)
    case syncEventMultipleItemPosition(SyncEventMultipleItemPosition)
    case startLocationSyncEvent(StartLocationSyncEvent)
    case startSyncEvent(StartSyncEvent)
  }

  struct SyncEvent {
    let itemPosition: ItemPosition
    let preSyncScanLocation: CGPoint
    let didSync: Bool
  }
  struct SyncEventMissingPosition {
    let identifier: String
  }
  struct SyncEventMultipleItemPosition {
    let item: Item
  }
  struct StartLocationSyncEvent {
    let startScanLocation: PositionedCode
  }
  struct StartSyncEvent {
    let itemPosition: ItemPosition
    let startDirection: Double
    let didSync: Bool
  }
}

