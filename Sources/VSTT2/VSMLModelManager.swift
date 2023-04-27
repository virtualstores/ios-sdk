//
//  VSMLModelManager.swift
//  
//
//  Created by Théodore Roos on 2023-03-07.
//

import Foundation

import CoreML
import CryptoKit
import CommonCrypto
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
    try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
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
          print("File", "Success", url)
          self._model = try! MLModel(contentsOf: url)
          //let parameter = try! self.model.parameterValue(for: .biases)
          //print("File", "Parameter", parameter)
          if let path = self.pathDirectory {
            try? self.fileManager.removeItem(at: path)
            try? self.fileManager.removeItem(at: url)
          }
          //print()
          //print("MODEL", self.model)
          print("File", "IT WORKS!!!!!!!!!!!!!!!!!!!!!!")
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
        guard let path = pathDirectory else { return }
        try fileManager.removeItem(at: path)
      } catch {
        print("CAN'T REMOVE FILE", error)
      }
      do {
        guard let data = data, let path = pathDirectory, let pathZip = pathZip, let pathEncrypted = pathEncrypted else { return }
//        try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        try data.write(to: pathEncrypted, options: .atomic)
//        try fileManager.removeItem(at: path)
        try decrypt(at: pathEncrypted, to: pathZip)
        try fileManager.unzipItem(at: pathZip, to: path)
        try fileManager.removeItem(at: pathZip)
        //if let date = attributes[.creationDate] as? Date {
        //  print("File", "AttributeCreationDate", date)
        //}
        completion(nil)
      } catch {
        completion(error)
      }
    }.resume()
  }

  func decrypt(at sourceURL: URL, to destinationURL: URL) throws {
    guard let data = fileManager.contents(atPath: sourceURL.relativePath) else { throw NSError(domain: "Gunnis did not like this", code: 500) }
    try CommonCryptoAES(key: "006438fb-cf23-4023-8bd3-064ee0b4".gunnis, data: data).decrypt()?.write(to: destinationURL)
    // TODO: Decrypt to pathZip
    // let box = try AES.GCM.SealedBox(combined: data)
    // let nonce = Data(data.enumerated().filter { $0.offset < 12 }.map { $0.element })
    // let cipherText = Data(data.enumerated().filter { $0.offset > 15 && $0.offset < data.count - 16 }.map { $0.element })
    // let tag = Data(data.enumerated().filter { $0.offset > data.count - 16 }.map { $0.element })
//    let nonce = Data(data.enumerated().filter { $0.offset < 16 }.map { $0.element })
//    let cipherText = Data(data.enumerated().filter { $0.offset > 15 }.map { $0.element })
    //let box2 = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonce), ciphertext: cipherText, tag: tag)
    //let key = Data(base64Encoded: "006438fb-cf23-4023-8bd3-064ee0b4".gunnis.data(using: .utf8)!.base64EncodedString())!
//    let key = "006438fb-cf23-4023-8bd3-064ee0b4".gunnis.data(using: .utf8)!.base64EncodedData()
    //let symmetricKey = SymmetricKey(data: key)
//    let authenticationCode = HMAC<SHA512>.authenticationCode(for: data, using: symmetricKey)
//    var isValid = false
//    if #available(iOS 13.2, *) {
//      print("SHOULD CHECK VALID")
//      isValid = HMAC<SHA512>.isValidAuthenticationCode(Data(authenticationCode),
//                                                           authenticating: data,
//                                                           using: symmetricKey)
//    }

//    print("VALID", isValid)
//    try AES.GCM.open(box2, using: symmetricKey, authenticating: Data(authenticationCode)).write(to: destinationURL)
    //try AES.GCM.open(box2, using: symmetricKey).write(to: destinationURL)

//    print("SYMKEY", symmetricKey.bitCount)
//    guard let key = sha256(string: "006438fb-cf23-4023-8bd3-064ee0b4".gunnis), let decryptedData = try AES256(key: key)?.decrypt(encryptedData: data) else { return }
//    try decryptedData.write(to: destinationURL)

//    try data.write(to: destinationURL)
  }

  func sha256(string: String) -> Data? {
    guard let messageData = string.data(using: .utf8) else { return nil }
    var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))

    _ = digestData.withUnsafeMutableBytes { (digestBytes) -> UnsafeMutablePointer<UInt8>? in
      messageData.withUnsafeBytes { (messageBytes) -> UnsafeMutablePointer<UInt8>? in
        CC_SHA256(messageBytes, CC_LONG(messageData.count), digestBytes)
      }
    }
    return digestData
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

  func unzipInMemory(data: Data) throws -> [String:Data] {
    var masterData = [String: Data]()
    let archive = Archive(data: data, accessMode: .read)!
    try archive.filter({ !$0.path.contains("__MACOSX/") }).forEach { (entry) in
      //print("ENTRY", entry.path)
      //try archive.extract(entry, to: path.appendingPathComponent(entry.path))
      let extraction = try archive.extract(entry) { (data) in
        //print("DATA", index, data)
        if masterData[entry.path] == nil { masterData[entry.path] = Data() }
        masterData[entry.path]?.append(data)
      }
      print("Extraction", extraction)
    }
    print()
    print()
    masterData.forEach { (key, value) in
      print("DATA", key, value)
    }
    //let entry = archive["newmodel.mlpackage/"]!
    //let extraction = try archive.extract(entry, to: path)
    //print("Extraction", extraction)
    return masterData
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

public struct AES256 {
  private let key: Data

  enum AESError: Error {
    case keySizeError
    case keyDataError
  }

  public init?(key: Data) throws {
    print("KEY", key, key.count)
//    guard key.count == kCCKeySizeAES256 else { throw AESError.keySizeError }
//    guard let keyData = key.data(using: .utf8) else { throw AESError.keyDataError }
    print("KEY1", key.count)
    self.key = key
  }

  public func encrypt(messageData: Data) -> Data? {
    return crypt(data: messageData, option: CCOperation(kCCEncrypt))
  }

  public func decrypt(encryptedData: Data) -> Data? {
    return crypt(data: encryptedData, option: CCOperation(kCCDecrypt))
  }

  private func crypt(data: Data, option: CCOperation) -> Data? {
    var outputBuffer = [UInt8](repeating: 0, count: data.count)
    var numBytesEncrypted = 0
    let iv = data.enumerated().filter { $0.offset < 16 }.map { $0.element }
    let dataIn = data.enumerated().filter { $0.offset > 15 }.map { $0.element }
    print("TEST", data.count)
    print("TEST", iv.count)
    print("TEST", dataIn.count)
    let status = CCCrypt(
      option,
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      Array(key),
      32,
      iv,
      dataIn,
      dataIn.count,
      &outputBuffer,
      outputBuffer.count,
      &numBytesEncrypted
    )
    print("STATUS", status)
    guard status == kCCSuccess else { return nil }
    print("BYTES", numBytesEncrypted)
    let outputBytes = outputBuffer.prefix(numBytesEncrypted)
    return Data(outputBytes)
  }
}

//let message = "testing that it encrypts and decrypts"
//let data = message.data(using: .utf8)
//let key = "Uc1gU2FsdGVkX19LW0ZSbvKUJT6TnTfI"
//
//let encryptedData = try? AES256(key: key)?.encrypt(messageData: data)
//if let decryptedData = try? AES256(key: key)?.decrypt(encryptedData: encryptedData) {
//  let decryptedMessage = String(data: decryptedData, encoding: .utf8)
//  if decryptedMessage == message {
//    print("Encryption and decryption successful")
//  } else {
//    print("Encryption and decryption failed")
//  }
//}

//extension String {
//    var md5: String { HMAC.hash(inp: self, algo: .MD5) }
//    var sha1: String { HMAC.hash(inp: self, algo: .SHA1) }
//    var sha224: String { HMAC.hash(inp: self, algo: .SHA224) }
//    var sha256: String { HMAC.hash(inp: self, algo: .SHA256) }
//    var sha384: String { HMAC.hash(inp: self, algo: .SHA384) }
//    var sha512: String { HMAC.hash(inp: self, algo: .SHA512) }
//}
//
//public struct HMAC {
//    static func hash(inp: String, algo: HMACAlgo) -> String {
//        if let stringData = inp.data(using: String.Encoding.utf8, allowLossyConversion: false) {
//            return hexStringFromData(input: digest(input: stringData as NSData, algo: algo))
//        }
//        return ""
//    }
//
//    private static func digest(input : NSData, algo: HMACAlgo) -> NSData {
//        let digestLength = algo.digestLength()
//        var hash = [UInt8](repeating: 0, count: digestLength)
//        switch algo {
//        case .MD5:
//            CC_MD5(input.bytes, UInt32(input.length), &hash)
//            break
//        case .SHA1:
//            CC_SHA1(input.bytes, UInt32(input.length), &hash)
//            break
//        case .SHA224:
//            CC_SHA224(input.bytes, UInt32(input.length), &hash)
//            break
//        case .SHA256:
//            CC_SHA256(input.bytes, UInt32(input.length), &hash)
//            break
//        case .SHA384:
//            CC_SHA384(input.bytes, UInt32(input.length), &hash)
//            break
//        case .SHA512:
//            CC_SHA512(input.bytes, UInt32(input.length), &hash)
//            break
//        }
//        return NSData(bytes: hash, length: digestLength)
//    }
//
//    private static func hexStringFromData(input: NSData) -> String {
//        var bytes = [UInt8](repeating: 0, count: input.length)
//        input.getBytes(&bytes, length: input.length)
//
//        var hexString = ""
//        for byte in bytes {
//            hexString += String(format:"%02x", UInt8(byte))
//        }
//
//        return hexString
//    }
//}
//
//enum HMACAlgo {
//    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
//
//    func digestLength() -> Int {
//        var result: CInt = 0
//        switch self {
//        case .MD5:
//            result = CC_MD5_DIGEST_LENGTH
//        case .SHA1:
//            result = CC_SHA1_DIGEST_LENGTH
//        case .SHA224:
//            result = CC_SHA224_DIGEST_LENGTH
//        case .SHA256:
//            result = CC_SHA256_DIGEST_LENGTH
//        case .SHA384:
//            result = CC_SHA384_DIGEST_LENGTH
//        case .SHA512:
//            result = CC_SHA512_DIGEST_LENGTH
//        }
//        return Int(result)
//    }
//}
