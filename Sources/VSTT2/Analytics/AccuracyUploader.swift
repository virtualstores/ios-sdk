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
import VSPositionKitTargets

class AccuracyUploader {
  @Inject var analytics: TT2AnalyticsManager
  @Inject var syncEventsService: UploadSyncEventsService
  @Inject var floorManager: VSTT2FloorManager

  let store: Store
  let connection: ServerConnection
  let client: Client
  let converter: ICoordinateConverter

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

  func upload(id: String, preScanLocation: CGPoint, position: ItemPosition, errorHandler: @escaping (Error) -> Void) {
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
      URLQueryItem(entry: .positionKitVersion, value: "PositionKit: 0.0.8"),//\(positionKitVersion)"),
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


    guard
      let visitId = analytics.visitId,
      let rtlsOptionsId = analytics.rtlsOptionId,
      let mapFence = floorManager.mapFence[rtlsOptionsId],
      let mapFenceData = MapFenceFactory.getMapFenceData(fromMapFence: mapFence)
    else { return }

    let preScanLocationInPixels = preScanLocation.fromMeterToPixel(converter: converter)
    let scanLocationInPixels = position.point.fromMeterToPixel(converter: converter)
    let isRightAisle = mapFenceData.isRightAisle(p1: preScanLocationInPixels, p2: scanLocationInPixels)

    var tags = ["identifier": position.identifier]
    if let shelfId = position.shelfId {
      tags["shelfId"] = String(shelfId)
    }
    let event = SyncEvent(
      rtlsOptionsId: rtlsOptionsId,
      identifier: position.identifier,
      isRightAisle: isRightAisle,
      isFloorSwap: false,
      didSync: true,
      rescueModeCountSinceLastSync: numberOfRescueModes,
      stepDataDistanceSinceLastSyncInMeters: 0,
      userToSyncPositionDistanceInMeters: calculateDistance(p1: preScanLocation, p2: position.point),
      errorAngleInDegrees: 0,
      timestamp: Date(),
      userPositionInMeters: preScanLocation,
      syncPositionInMeters: position.point,
      syncPositionOffsetsInMeters: offset,
      tags: tags
    )
    let parameters = UploadSyncEventsParameters(
      config: config,
      visitId: visitId,
      requestId: UUID().uuidString.uppercased(),
      event: event
    )
    upload(parameters: parameters)
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

      }.store(in: &cancellable)
  }

  func calculateDistance(p1: CGPoint, p2: CGPoint) -> Double {
    print("distance1",p1.distance(to: p2))
    let x = p2.x - p1.x
    let y = p2.y - p1.y
    print("distance2", (pow(x, 2) + pow(y, 2)).squareRoot())
    return (pow(x, 2) + pow(y, 2)).squareRoot()
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
