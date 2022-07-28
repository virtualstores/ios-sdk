//
//  DeviceOrientationUploader.swift
//  
//
//  Created by Théodore Roos on 2022-07-26.
//

import Foundation
import UIKit

class DeviceOrientationUploader {
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

  func upload(id: String, visitId: Int64, deviceOrientation: String, currentLocation: CGPoint, direction: Double, errorHandler: @escaping (Error) -> Void) {
    print(#function, "Test to upload")
    guard
      let serverAddress = connection.serverAddress,
      let clientName = client.name,
      //let positionKitVersion = Bundle(identifier: "org.cocoapods.PositionKit")?.infoDictionary?["CFBundleShortVersionString"] as? String,
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
      URLQueryItem(entry: .positionKitVersion, value: "PositionKit: 0.0.8"),//\(positionKitVersion)"),
      URLQueryItem(entry: .serverUrl, value: "\(serverAddress)"),
      URLQueryItem(entry: .clientId, value: "\(client.clientId), \(clientName)"),
      URLQueryItem(entry: .storeId, value: "\(store.id), \(store.name)"),
      URLQueryItem(name: "submit", value: "Submit")
    ]

    guard let url = urlComponents.url else { return }

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
