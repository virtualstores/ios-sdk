//
//  DeviceOrientationUploader.swift
//  
//
//  Created by Théodore Roos on 2022-07-26.
//

import Foundation
import UIKit
import VSFoundation
import VSPositionKit

class DeviceOrientationUploader {
  @Inject var config: EnvironmentConfig
  @Inject var getActiveClient: GetActiveClientUseCase
  @Inject var getActiveStore: GetActiveStoreUseCase

  var client: Client? { try? getActiveClient.invoke() }
  var store: Store? { try? getActiveStore.invoke() }

  public enum Errors: Error {
    case uploadFailure(HTTPURLResponse)
  }

  func upload(id: String, visitId: Int64, deviceOrientation: String, currentLocation: CGPoint, direction: Double, errorHandler: @escaping (Error) -> Void) {
    guard
      let serverAddress = config.connection.tt2DataServer?.baseUrl,
      let clientName = client?.name,
      let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
      let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    else { return }

    var urlComponents = URLComponents()

    let systemName = UIDevice.current.systemName
    let systemVersion = UIDevice.current.systemVersion
    let modelName = UIDevice.current.modelName

    let userId = UserDefaults.standard.string(forKey: "USERID")
    let xPosition = currentLocation.x
    let yPosition = currentLocation.y
    let combinedInfo = (userId ?? "") + ", " + deviceOrientation + ", " + "(\(xPosition), \(yPosition))" + ", " + "\(direction)"

    urlComponents.scheme = "https"
    urlComponents.host = "docs.google.com"
    #if DEBUG
    urlComponents.path = "/forms/d/e/1FAIpQLSeVsnwtfyL3YH5ePhAQv4VYQZpOCLK4nuzsaVnOiKfUHbg39g/formResponse"
    #else
    urlComponents.path = "/forms/d/e/1FAIpQLSebBRcbB13vlMu9fOVPs6RCQqcxa6E0g212Bv9vm0NDeTdRvg/formResponse"
    #endif

    urlComponents.queryItems = [
      URLQueryItem(entry: .sessionId, value: id),
      URLQueryItem(entry: .visitId, value: String(visitId)),
      URLQueryItem(entry: .articleId, value: combinedInfo),
      URLQueryItem(entry: .appVersion, value: "\(appVersion) (\(buildNumber)), \(systemName) \(systemVersion), \(modelName)"),
      URLQueryItem(entry: .positionKitVersion, value: vpsVersion),
      URLQueryItem(entry: .serverUrl, value: "\(serverAddress)"),
      URLQueryItem(entry: .clientId, value: "\(client?.clientId), \(clientName)"),
      URLQueryItem(entry: .storeId, value: "\(store?.id), \(store?.name)"),
      URLQueryItem(name: "submit", value: "Submit")
    ]

    guard let url = urlComponents.url else { return }

    //Logger(verbosity: .info).log(message: "DeviceOrientationUploader: \(url)")
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
