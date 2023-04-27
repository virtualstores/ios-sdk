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
    let dataPart = Data(data.enumerated().filter { $0.offset >= 16 }.map { $0.element })
    let iv = Data(data.enumerated().filter { $0.offset < 16 }.map { $0.element })
    let aes = try AES(key: Array(key.data(using: .utf8)!.sha256()), blockMode: CBC(iv: Array(iv)))
    print("AES", aes)
    print("dataPart", dataPart, dataPart.count)
    print("iv", iv, iv.count)
    let date = Date()
    let shit = try Data(aes.decrypt(Array(dataPart)))
    print("TIME", Date().timeIntervalSince(date))
    return shit
  }
}
