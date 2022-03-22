//
//  AccuracyUploader.swift
//  
//
//  Created by Théodore Roos on 2022-03-22.
//

import Foundation
import UIKit

class AccuracyUploader {
  let store: Store
  let connection: ServerConnection
  let client: Client

  public enum Errors: Error {
    case uploadFailure(HTTPURLResponse)
  }

  init(store: Store, connection: ServerConnection, client: Client) {
    self.store = store
    self.connection = connection
    self.client = client
  }

  func upload(id: String, articleId: String, preScanLocation: CGPoint, offset: CGVector, scanLocation: CGPoint, errorHandler: @escaping (Error) -> Void) {
    guard
      let serverAddress = connection.serverAddress,
      let clientName = client.name,
      //let positionKitVersion = Bundle(identifier: "org.cocoapods.PositionKit")?.infoDictionary?["CFBundleShortVersionString"] as? String,
      let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
      let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    else {
      return
    }
    var urlComponents = URLComponents()

    // Ternary operator
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

//    urlComponents.queryItems = [
//      URLQueryItem(name: "entry.723772527", value: id),
//      URLQueryItem(name: "entry.234712389", value: articleId),
//      URLQueryItem(name: "entry.421535035", value: "\(preScanLocation.x)"),
//      URLQueryItem(name: "entry.1326043207", value: "\(height - preScanLocation.y)"),
//      URLQueryItem(name: "entry.1258351828", value: "\(dx)"),
//      URLQueryItem(name: "entry.708563230", value: "\(dy)"),
//      URLQueryItem(name: "entry.832291956", value: "\(scanLocation.x)"),
//      URLQueryItem(name: "entry.1411294416", value: "\(height - scanLocation.y)"),
//      URLQueryItem(name: "entry.1892335868", value: "\(appVersion) (\(buildNumber)), \(systemName) \(systemVersion), \(modelName)"),
//      URLQueryItem(name: "entry.827959482", value: "PositionKit: \(positionKitVersion)"),
//      URLQueryItem(name: "entry.548783748", value: "\(api.centralConnection.serverUrl)"),
//      URLQueryItem(name: "entry.1270289197", value: "\(api.clientId), \(client.name)"),
//      URLQueryItem(name: "entry.1258341166", value: "\(store.id), \(store.name)"),
//      URLQueryItem(name: "submit", value: "Submit")
//    ]

    urlComponents.queryItems = [
      URLQueryItem(entry: .sessionId, value: id),
      URLQueryItem(entry: .articleId, value: articleId),
      URLQueryItem(entry: .preScanLocationX, value: "\(preScanLocation.x)"),
      URLQueryItem(entry: .preScanLocationY, value: "\(preScanLocation.y)"),
      URLQueryItem(entry: .offsetX, value: "\(dx)"),
      URLQueryItem(entry: .offsetY, value: "\(dy)"),
      URLQueryItem(entry: .scanLocationX, value: "\(scanLocation.x)"),
      URLQueryItem(entry: .scanLocationY, value: "\(scanLocation.y)"),
      URLQueryItem(entry: .appVersion, value: "\(appVersion) (\(buildNumber)), \(systemName) \(systemVersion), \(modelName)"),
      URLQueryItem(entry: .positionKitVersion, value: "PositionKit: 0.0.6"),//\(positionKitVersion)"),
      URLQueryItem(entry: .serverUrl, value: "\(serverAddress)"),
      URLQueryItem(entry: .clientId, value: "\(client.clientId), \(clientName)"),
      URLQueryItem(entry: .storeId, value: "\(store.id), \(store.name)"),
      URLQueryItem(name: "submit", value: "Submit")
    ]

    guard let url = urlComponents.url else {
      return
    }

    print(url)
    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
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
    }

    task.resume()
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
  }

  init(entry: EntryIDs, value: String) {
    self.init(name: entry.rawValue, value: value)
  }
}
