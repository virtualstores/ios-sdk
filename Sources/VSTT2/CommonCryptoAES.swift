//
//  CommonCryptoAES.swift
//  
//
//  Created by Théodore Roos on 2023-04-27.
//

import Foundation
import CommonCrypto

struct CommonCryptoAES {
  let key: String
  let data: Data

  func decrypt() throws -> Data? {
    var outputBuffer = [UInt8](repeating: 0, count: data.count)
    var numBytesEncrypted = 0
    let dataPart = data.dataPart
    let status = CCCrypt(
      CCOperation(kCCDecrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      Array(sha256(string: key)!),
      32,
      data.iv,
      dataPart,
      dataPart.count,
      &outputBuffer,
      outputBuffer.count,
      &numBytesEncrypted
    )
    guard status == kCCSuccess else { return nil }
    return Data(outputBuffer.prefix(numBytesEncrypted))
  }

  func sha256(string: String) -> Data? {
    guard let messageData = string.data(using: .utf8) else { return nil }
    var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))

    digestData.withUnsafeMutableBytes { (digestBytes) in
      messageData.withUnsafeBytes { (messageBytes) in
        CC_SHA256(messageBytes, CC_LONG(messageData.count), digestBytes)
      }
    }

    return digestData
  }
}

private extension Data {
  var dataPart: Array<Data.Element> { Array(Array(self)[16..<count]) }
  var iv: Array<Data.Element> { Array(Array(self)[0..<16]) }
}
