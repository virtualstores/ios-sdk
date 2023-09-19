//
// BarcodePosition
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation
import CoreGraphics

struct BarcodePosition: Codable {
  let rtlsOptionsId: Int64?
  let shelfId: Int64?
  let shelfTierId: Int64?
  let shelfTierPosition: Int64?
  let barcode: String?
  let isDisabled: Bool?
  let itemPositionX: Double?
  let itemPositionY: Double?
  let itemPositionOffsetX: Double?
  let itemPositionOffsetY: Double?

  var itemPosition: CGPoint? {
    guard let x = itemPositionX, let y = itemPositionY else { return nil }
    return CGPoint(x: x, y: y)
  }

  var itemPositionOffset: CGVector? {
    guard let x = itemPositionOffsetX, let y = itemPositionOffsetY else { return nil }
    return CGVector(dx: x, dy: y)
  }

  init(rtlsOptionsId: Int64?, shelfId: Int64?, shelfTierId: Int64?, shelfTierPosition: Int64?, itemPositionX: Double?, itemPositionY: Double?, itemPositionOffsetX: Double?, itemPositionOffsetY: Double?, barcode: String?, isDisabled: Bool? = nil) {
    self.rtlsOptionsId = rtlsOptionsId
    self.shelfId = shelfId
    self.shelfTierId = shelfTierId
    self.shelfTierPosition = shelfTierPosition
    self.barcode = barcode
    self.isDisabled = isDisabled
    self.itemPositionX = itemPositionX
    self.itemPositionY = itemPositionY
    self.itemPositionOffsetX = itemPositionOffsetX
    self.itemPositionOffsetY = itemPositionOffsetY
  }
}
