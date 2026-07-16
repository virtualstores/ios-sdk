//
// Item
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

public class Item {
  public var name: String
  public var externalId: String
  public var itemPositions: [ItemPosition]
  public var uniquePositions: [ItemPosition] { unique() }
  public var itemPosition: ItemPosition?
  public var zonePosition: ZonePosition?

  public init(name: String, externalId: String, itemPositions: [ItemPosition], itemPosition: ItemPosition?, zonePosition: ZonePosition?) {
    self.name = name
    self.externalId = externalId
    self.itemPositions = itemPositions
    self.itemPosition = itemPosition
    self.zonePosition = zonePosition
  }

  /// Will use the first **itemPosition** in `itemPositions`
  public convenience init (name: String, externalId: String, itemPositions: [ItemPosition]) {
    self.init(name: name, externalId: externalId, itemPositions: itemPositions, itemPosition: itemPositions.first, zonePosition: nil)
  }

  private func checkForMaxAllowedDistinctItemPositions(max: Int = 1) -> Bool {
    unique().count == max
  }

  private func unique() -> [ItemPosition] {
    var uniquePositions: [ItemPosition] = []
    itemPositions.map { $0.shelfId }.compactMap { $0 }.uniqued().forEach { (shelfId) in
      guard let position = itemPositions.first(where: { $0.shelfId == shelfId }) else { return }
      uniquePositions.append(position)
    }
    return uniquePositions
  }
}

extension Array where Element: Hashable {
  func uniqued() -> Array {
    var buffer = Array()
    var added = Set<Element>()
    forEach { (elem) in
      if !added.contains(elem) {
        buffer.append(elem)
        added.insert(elem)
      }
    }
    return buffer
  }
}

public struct ItemSettings {
  let zoneLookupScope: ZoneLookupScope
  let obfuscateBarcode: Bool

  public init(zoneLookupScope: ZoneLookupScope = .parentOnly, obfuscateBarcode: Bool = false) {
    self.zoneLookupScope = zoneLookupScope
    self.obfuscateBarcode = obfuscateBarcode
  }

  public enum ZoneLookupScope: String {
    case parentOnly = "PARENT_ONLY"
    case childOnly = "CHILD_ONLY"
    case childThenParent = "CHILD_THEN_PARENT"
  }
}
