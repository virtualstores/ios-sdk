//
//  VSMLModelManager.swift
//  
//
//  Created by Théodore Roos on 2023-03-07.
//

import Foundation
import Combine
import CoreML
import VSFoundation
import ZIPFoundation

class VSMLModelManager {
  @Inject var mlInterfaceVersionService: MLInterfaceVersionsService
  private var cancellable = Set<AnyCancellable>()

  private let fileManager = FileManager.default
  private var mlInterfaceVersion: String { "1" } // TODO: Get this from VPS in future
  //private var info: [MLInterfaceInfo] = []
  private var currentVersion: MLInterfaceVersions.Interface.Device.Version? {
    get {
      guard let data = UserDefaults.standard.value(forKey: "TT2CURRENTMLINTERFACEVERSION") as? Data else { return nil }
      return try? JSONDecoder().decode(MLInterfaceVersions.Interface.Device.Version.self, from: data)
    }
    set {
      guard let encoded = try? JSONEncoder().encode(newValue) else { return }
      UserDefaults.standard.setValue(encoded, forKey: "TT2CURRENTMLINTERFACEVERSION")
    }
  }
  private var _model: MLModel?
  private var modelName = ""
  var pathDirectory: URL? {
    try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("MLModel")
  }
  var pathMLModel: URL? { pathDirectory?.appendingPathComponent(modelName).appendingPathExtension("mlpackage") }
  var pathEncrypted: URL? { pathDirectory?.appendingPathExtension("encrypted") }

  init() {
    if let path = pathDirectory {
      try? fileManager.removeItem(at: path)
    }
    loadVersion { [self] (result) in
      switch result {
      case .success(let versions):
        //print("File", "Success getting Version")
        guard let interface = versions.interfaces[mlInterfaceVersion]?.iOS else { return }
        var version: MLInterfaceVersions.Interface.Device.Version?
        if let v = interface.versions[interface.latestVersion], !v.deprecated {
          version = v
        } else if let v = interface.versions.first(where: { !$0.value.deprecated }) {
          version = v.value
        }
        guard let version = version else { return }
        loadModel(version: version) { [self] (error) in
          currentVersion = version
          if let error = error {
            print("File", "Error getting MLModel", error)
            return
          }
          compileModel { [self] (result) in
            switch result {
            case .success(let url):
              //print("File", "Success", url)
              let config = MLModelConfiguration()
              config.computeUnits = .cpuOnly
              _model = try! MLModel(contentsOf: url, configuration: config)
              //let parameter = try! self.model.parameterValue(for: .biases)
              //print("File", "Parameter", parameter)
              if let path = self.pathDirectory {
                try? fileManager.removeItem(at: path)
                try? fileManager.removeItem(at: url)
              }
              //print("File", "IT WORKS!!!!!!!!!!!!!!!!!!!!!!")
            case .failure(let error): print("File", "Error compiling model", error.localizedDescription)
            }
          }
        }
      case .failure(let error): print("File", "Error getting Version", error)
      }
    }
  }

  func loadVersion(completion: @escaping (Result<MLInterfaceVersions, Error>) -> Void) {
    mlInterfaceVersionService
      .call(with: MLInterfaceVersionsParameters())
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error): completion(.failure(error))
        }
      } receiveValue: { (versions) in
        //versions.print()
        completion(.success(versions))
      }.store(in: &cancellable)
  }

  func loadModel(version: MLInterfaceVersions.Interface.Device.Version, completion: @escaping (Error?) -> Void) {
    if let currentVersion = currentVersion, currentVersion.modelVersion == version.modelVersion {
      //print("LOADING SAVED MODEL")
      do {
        guard let path = pathDirectory, let pathEncrypted = pathEncrypted else { return }
        guard let decrypted = try decrypt(id: version.id, at: pathEncrypted) else { throw NSError() }
        try unzipInMemory(data: decrypted, to: path)
        completion(nil)
      } catch {
        completion(error)
      }
    } else {
      guard let url = URL(string: version.modelUrl) else { return }
      //print("VERSION", version.modelVersion)
      URLSession.shared.dataTask(with: url) { [self] (data, response, error) in
        //print("DOWNLOADING MODEL")
        //guard let response = response as? HTTPURLResponse else { return }
        //print("File", "MLResponse", response.statusCode)
        if error != nil {
          completion(error)
          return
        }

        do {
          guard let data = data, let path = pathDirectory, let pathEncrypted = pathEncrypted else { return }
          try data.write(to: pathEncrypted, options: .atomic)
          guard let decrypted = try decrypt(id: version.id, at: pathEncrypted) else { throw NSError() }
          try unzipInMemory(data: decrypted, to: path)
          completion(nil)
        } catch {
          completion(error)
        }
      }.resume()
    }
  }

  func decrypt(id: String, at sourceURL: URL) throws -> Data? {
    guard let data = fileManager.contents(atPath: sourceURL.relativePath) else { throw NSError(domain: "Gunnis did not like this", code: 500) }
    return CommonCryptoAES(key: id.gunnis, data: data).decrypt()
  }

  func compileModel(completion: @escaping (Result<URL, Error>) -> Void) {
    guard let path = pathMLModel else { return }
    if #available(iOS 16.0, *) {
      MLModel.compileModel(at: path, completionHandler: completion)
    } else {
      do {
        completion(.success(try MLModel.compileModel(at: path)))
      } catch {
        completion(.failure(error))
      }
    }
  }

  func unzipInMemory(data: Data, to destinationURL: URL) throws {
    guard let archive = Archive(data: data, accessMode: .read) else { throw NSError() } // TODO: Create better error message
    try archive.filter({ !$0.path.contains("__MACOSX/") }).forEach { (entry) in
      //print("PATH", entry.path)
      if entry.path.hasSuffix(".mlpackage/") {
        var modelName = entry.path
        modelName.removeLast(".mlpackage/".count)
        //print("SAVE PATH COMPONENT", modelName)
        self.modelName = modelName
      }
      _ = try archive.extract(entry, to: destinationURL.appendingPathComponent(entry.path))
    }
  }
}

extension VSMLModelManager: VPSModelManager {
  var model: MLModel? {
    guard let model = _model else { return nil }
    return model
  }
}

extension String {
  var gunnis: String {
    self + replacingOccurrences(of: "-", with: "8")
      .replacingOccurrences(of: "0", with: "9")
      .map { Int(String($0), radix: 16) }
      .compactMap { $0 }
      .split(into: 4)
      .map { $0.reduce(1) { ($0 * $1) % 9999 } }
      .map { String(format: "%04d", $0) }
      .joined()
  }
}

extension Array {
  func split(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size)
      .map { Array(self[$0..<Swift.min($0 + size, count)]) }
  }
}
