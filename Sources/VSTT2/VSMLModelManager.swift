//
//  VSMLModelManager.swift
//  
//
//  Created by Théodore Roos on 2023-03-07.
//

import Foundation

import CoreML
import ZIPFoundation

class VSMLModelManager {
  let fileManager = FileManager.default
  let s3MlVersionUrlString = "https://virtualstores-assets.s3.eu-north-1.amazonaws.com/sdk-assets/ml-interface/MLInterfaceVersions.json"
  let s3MlModelUrlString = "https://virtualstores-assets.s3.eu-north-1.amazonaws.com/sdk-assets/ml-interface/core-ml-interfaces/newmodel.mlpackage.zip"
  let encrypteru = "https://virtualstores-assets.s3.eu-north-1.amazonaws.com/sdk-assets/ml-interface/core-ml-interfaces/encryptedModel"
  var mlInterfaceVersion: Int { 1 } // TODO: Get this from VPS in future
  var info: [MLInterfaceInfo] = []
  var currentInfo: MLInterfaceInfo?
  private var _model: MLModel?
  var model: MLModel {
    guard let model = _model else { fatalError("model not yet saved") }
    return model
  }
  var pathDirectory: URL? {
    try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("MLModel")
  }
  var pathZip: URL? { pathDirectory?.appendingPathExtension("zip") }
  var pathMLModel: URL? { pathDirectory?.appendingPathComponent("newmodel").appendingPathExtension("mlpackage") }
  var pathEncrypted: URL? { pathDirectory?.appendingPathExtension("encrypted") }
  var attributes: [FileAttributeKey:Any] {
    guard
      let path = pathMLModel,
      let dict = try? fileManager.attributesOfItem(atPath: path.relativePath)
    else { return [:] }
    return dict
  }

  init() {
    //    if let path = pathDirectory, let pathZip = pathZip, let pathMLModel = pathMLModel {
    //      print("File", "Directory", path, path.relativePath)
    //      print("File", "Directory", pathZip, pathZip.relativePath)
    //      print("File", "Directory", pathMLModel, pathMLModel.relativePath)
    //    }
    //    if let date = attributes[.creationDate] as? Date {
    //      print("File", "AttributeCreationDate", date)
    //    }
    do {
      guard let path = pathDirectory else { return }
      try fileManager.removeItem(at: path)
    } catch {
      //print("CAN'T REMOVE FILE", error)
    }
    loadVersion { /*[self]*/ (error) in
      if let error = error {
        print("File", "Error getting Version", error)
        return
      }

      //      print("File", "Success getting Version")
      //      info.forEach { print("File", "INFO", $0) }
    }
    loadModel() { [self] (error) in
      if let error = error {
        print("File", "Error getting MLModel", error)
        return
      }
      compileModel { (result) in
        switch result {
        case .success(let url):
          //print("File", "Success", url)
          self._model = try! MLModel(contentsOf: url)
          //let parameter = try! self.model.parameterValue(for: .biases)
          //print("File", "Parameter", parameter)
          if let path = self.pathDirectory {
            try? self.fileManager.removeItem(at: path)
            try? self.fileManager.removeItem(at: url)
          }
          //print()
          //print("MODEL", self.model)
          //print("File", "IT WORKS!!!!!!!!!!!!!!!!!!!!!!")
        case .failure(let error): print("File", "Error compiling model", error.localizedDescription)
        }
      }
    }
  }

  func loadVersion(completion: @escaping (Error?) -> Void) {
    return
    URLSession.shared.dataTask(with: URL(string: s3MlVersionUrlString)!) { (data, response, error) in
      //      guard let response = response as? HTTPURLResponse else { return }
      //      print("File", "VersionResponse", response.statusCode)
      if error != nil {
        completion(error)
        return
      }

      do {
        guard
          let data = data,
          let dict = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? NSDictionary,
          let interfaces = dict[String(self.mlInterfaceVersion)] as? NSDictionary,
          let interface = interfaces["iOS"] as? NSDictionary
        else { return }

        self.info.removeAll()
        interface.forEach {
          guard
            let dict = $0.value as? NSDictionary,
            let version = dict["modelVersion"] as? Int,
            let url = dict["modelUrl"] as? String,
            let name = dict["name"] as? String
          else { return }
          self.info.append(MLInterfaceInfo(modelVersion: version, modelUrl: url, name: name))
        }
        completion(nil)
      } catch {
        completion(error)
      }
    }.resume()
  }

  func loadModel(completion: @escaping (Error?) -> Void) {
    URLSession.shared.dataTask(with: URL(string: encrypteru)!) { [self] (data, response, error) in
      //      guard let response = response as? HTTPURLResponse else { return }
      //      print("File", "MLResponse", response.statusCode)
      if error != nil {
        completion(error)
        return
      }

      do {
        guard let data = data, let path = pathDirectory, let pathZip = pathZip, let pathEncrypted = pathEncrypted else { return }
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
      MLModel.compileModel(at: path) { (result) in
        switch result {
        case .success(let url): completion(.success(url))
        case .failure(let error): completion(.failure(error))
        }
      }
    } else {
      do {
        completion(.success(try MLModel.compileModel(at: path)))
      } catch {
        completion(.failure(error))
      }
    }
  }

  func unzipInMemory(data: Data, to destinationURL: URL) throws {
    let archive = Archive(data: data, accessMode: .read)!
    try archive.filter({ !$0.path.contains("__MACOSX/") }).forEach { (entry) in
      _ = try archive.extract(entry, to: destinationURL.appendingPathComponent(entry.path))
    }
  }
}

extension VSMLModelManager {
  struct MLInterfaceInfo {
    let modelVersion: Int
    let modelUrl: String
    let name: String
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
