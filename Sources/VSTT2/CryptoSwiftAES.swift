//
//  File.swift
//  
//
//  Created by Théodore Roos on 2023-04-27.
//

import Foundation
import CryptoSwift

struct CryptoSwiftAES {
  let key: String
  let data: Data

  func decrypt() throws -> Data? {
    let aes = try AES(key: Array(key.data(using: .utf8)!.sha256()), blockMode: CBC(iv: Array(data.iv)))
//    print("AES", aes)
//    print("dataPart", data.dataPart, data.dataPart.count)
//    print("iv", data.iv, data.iv.count)
    let date = Date()
    let shit = try Data(aes.decrypt(Array(data.dataPart)))
    print("TIME", Date().timeIntervalSince(date))
    return shit
  }
}

import CommonCrypto
struct CommonCryptoAES {
  let key: String
  let data: Data

  func decrypt() throws -> Data? {
    var outputBuffer = [UInt8](repeating: 0, count: data.count)
    var numBytesEncrypted = 0
    let date = Date()
    let dataPart = data.dataPart
    let status = CCCrypt(
      CCOperation(kCCDecrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      Array(key.data(using: .utf8)!.sha256()),
      32,
      data.iv,
      dataPart,
      dataPart.count,
      &outputBuffer,
      outputBuffer.count,
      &numBytesEncrypted
    )
    print("STATUS", status)
    print("TIME", Date().timeIntervalSince(date))
    guard status == kCCSuccess else { return nil }
    print("BYTES", numBytesEncrypted)
    let outputBytes = outputBuffer.prefix(numBytesEncrypted)
    return Data(outputBytes)
  }
}

extension Data {
//  var dataPart: Data { Data(enumerated().filter { $0.offset >= 16 }.map { $0.element }) }
//  var iv: Data { Data(enumerated().filter { $0.offset < 16 }.map { $0.element }) }
  var dataPart: Array<Data.Element> { Array(Array(self)[16..<count]) }
  var iv: Array<Data.Element> { Array(Array(self)[0..<16]) }
}
