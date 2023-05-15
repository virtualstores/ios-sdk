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
  private var currentVersion: MLInterfaceVersions.Interface.Device.Version?
  private var _model: MLModel?
  var model: MLModel {
    guard let model = _model else { fatalError("model not yet saved") }
    return model
  }
  var pathDirectory: URL? {
    try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("MLModel")
  }
  var pathMLModel: URL? { pathDirectory?.appendingPathComponent("newmodel").appendingPathExtension("mlpackage") }
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
        loadModel(url: version.modelUrl) { [self] (error) in
          if let error = error {
            print("File", "Error getting MLModel", error)
            return
          }
          compileModel { [self] (result) in
            switch result {
            case .success(let url):
              //print("File", "Success", url)
              _model = try! MLModel(contentsOf: url)
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

  func loadModel(url: String, completion: @escaping (Error?) -> Void) {
    guard let url = URL(string: url) else { return }
    URLSession.shared.dataTask(with: url) { [self] (data, response, error) in
      //guard let response = response as? HTTPURLResponse else { return }
      //print("File", "MLResponse", response.statusCode)
      if error != nil {
        completion(error)
        return
      }

      do {
        guard let data = data, let path = pathDirectory, let pathEncrypted = pathEncrypted else { return }
        try data.write(to: pathEncrypted, options: .atomic)
        guard let decrypted = try decrypt(at: pathEncrypted) else { throw NSError() }
        try unzipInMemory(data: decrypted, to: path)
        //if let date = attributes[.creationDate] as? Date {
        //  print("File", "AttributeCreationDate", date)
        //}
        completion(nil)
      } catch {
        completion(error)
      }
    }.resume()
  }

  func decrypt(at sourceURL: URL) throws -> Data? {
    guard let data = fileManager.contents(atPath: sourceURL.relativePath) else { throw NSError(domain: "Gunnis did not like this", code: 500) }
    return try CommonCryptoAES(key: "006438fb-cf23-4023-8bd3-064ee0b4".gunnis, data: data).decrypt()
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
        var test = entry.path
        test.removeLast(".mlpackage/".count)
        //print("SAVE PATH COMPONENT", test)
      }
      _ = try archive.extract(entry, to: destinationURL.appendingPathComponent(entry.path))
    }
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
