//
//  GetByBarcodeUseCaseTests.swift
//  
//
//  Created by Théodore Roos on 2022-12-16.
//

import Combine
import Foundation
import VSFoundation
import XCTest
@testable import VSTT2

final class GetByBarcodeUseCaseTests: XCTestCase {
  var cancellables = Set<AnyCancellable>()

  func test_that_given_activeStore_and_items_where_all_positions_has_the_same_shelfId_does_not_return_nil() {
    let storeRepository = FakeStoreRepository(jsonData: .storeFixture)
    var itemsRepository = FakeItemsRepository(jsonData: .mockBarcodePositionsCase1)

    let barcode = "7313130215910"
    let usecase = GetPositionByBarcodeUseCase()
    usecase.invoke(barcode: barcode)
      .asResult()
      .sink { (result) in
        switch result {
        case .failure(let error): break
        case .success(let item):
          XCTAssertNotNil(item.itemPosition, "ItemPosition is nil")
        }
      }
      .store(in: &cancellables)

    itemsRepository = FakeItemsRepository(jsonData: .mockBarcodePositionsCase2)

    usecase.invoke(barcode: barcode)
      .asResult()
      .sink { (result) in
        switch result {
        case .failure(let error): break
        case .success(let item):
          XCTAssertNotNil(item.itemPosition, "ItemPosition is nil")
        }
      }
      .store(in: &cancellables)
  }

  func test_that_given_activeStore_and_items_where_all_positions_does_not_have_the_same_shelfId_does_return_nil() {
    let storeRepository = FakeStoreRepository(jsonData: .storeFixture)
    let itemsRepository = FakeItemsRepository(jsonData: .mockBarcodePositionsCase3)

    let barcode = "7313130215910"
    GetPositionByBarcodeUseCase().invoke(barcode: barcode)
      .asResult()
      .sink { (result) in
        switch result {
        case .failure(let error): break
        case .success(let item):
          XCTAssertNil(item.itemPosition, "ItemPosition is nil")
        }
      }
      .store(in: &cancellables)
  }
}

class FakeStoreRepository: IStoreRepository {
  var zonesTree: VSTT2.TT2ZonesTree { TT2ZonesTree() }
  let jsonData: String
  var _activeStore: Store? {
    guard
      let jsonData = jsonData.data(using: .utf8),
      let storeList: StoresList = try? JSONDecoder().decode(StoresList.self, from: jsonData)
    else { return nil }

    return storeList.stores.first
  }
  var activeStore: Store {
    guard let store = _activeStore else { fatalError("No Active Store") }
    return store
  }

  init(jsonData: String) {
    self.jsonData = jsonData
  }

  func dispose() {}
  func fetchStores(clientId: Int64, completion: @escaping ((any Error)?) -> ()) {}
  func fetchSwapLocations(storeId: Int64, completion: @escaping ((any Error)?) -> ()) {}
  func getCachedSwapLocations() -> [SwapLocation] { [] }
  func set(activeStore store: Store) {}
  func set(cachedStores stores: [Store]) {}
  func getStores(clientId: Int64, completion: @escaping (Result<[VSTT2.Store], Error>) -> Void) {}
  func getCachedStores() -> [VSTT2.Store] { [activeStore] }
  func setCachedStores(stores: [VSTT2.Store]) {}
  func setActiveStore(store: VSTT2.Store) {}
  func fetchStores(clientId: Int64) -> AnyPublisher<Void, any Error> {
    return .fail(with: TT2Error.missingData)
  }

  func fetchSwapLocations(storeId: Int64) -> AnyPublisher<Void, any Error> {
    return .fail(with: TT2Error.missingData)
  }
}

class FakeItemsRepository: IItemsRepository {
  let jsonData: String
  var cachedItems: [String:Item] = [:]

  init(jsonData: String) {
    self.jsonData = jsonData
  }

  func dispose() {}

  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[VSTT2.BarcodePosition], Error>) -> ()) {
    guard
      let json = jsonData.data(using: .utf8),
      let barcodePositions: [BarcodePosition] = try? JSONDecoder().decode([BarcodePosition].self, from: json)
    else { XCTFail("Failed to parse barcode positions"); return }

    completion(.success(barcodePositions))
  }

  func getCachedItems(by barcode: String) -> VSTT2.Item? { cachedItems[barcode] }
  func addCachedItem(item: VSTT2.Item) { cachedItems[item.externalId] = item }
  func reset() { cachedItems.removeAll() }
  func getBy(storeId: Int64, barcode: String) -> AnyPublisher<[VSTT2.BarcodePosition], any Error> {
    return .fail(with: TT2Error.missingData)
  }

  func getCachedItems(by identfier: String) -> [VSTT2.BarcodePosition]? {
    nil
  }

  func addCachedItem(identfier: String, positons: [VSTT2.BarcodePosition]) {

  }
}

fileprivate extension String {
  static var mockBarcodePositionsCase1: String {
    """
    [
      {
        "rtlsOptionsId": 74,
        "shelfId": 20111,
        "shelfTierId": 48588,
        "shelfTierPosition": 5,
        "itemPositionX": 33.53869897997127,
        "itemPositionY": 68.48717115152746,
        "itemPositionOffsetX": 0.9025812149047852,
        "itemPositionOffsetY": -0.430519700050354,
        "barcode": "7313130215910"
      }
    ]
    """
  }

  static var mockBarcodePositionsCase2: String {
    """
    [
      {
        "rtlsOptionsId": 74,
        "shelfId": 20111,
        "shelfTierId": 48588,
        "shelfTierPosition": 5,
        "itemPositionX": 33.53869897997127,
        "itemPositionY": 68.48717115152746,
        "itemPositionOffsetX": 0.9025812149047852,
        "itemPositionOffsetY": -0.430519700050354,
        "barcode": "7313130215910"
      },
      {
        "rtlsOptionsId": 74,
        "shelfId": 20111,
        "shelfTierId": 48588,
        "shelfTierPosition": 5,
        "itemPositionX": 33.53869897997127,
        "itemPositionY": 68.48717115152746,
        "itemPositionOffsetX": 0.9025812149047852,
        "itemPositionOffsetY": -0.430519700050354,
        "barcode": "7313130215910"
      }
    ]
    """
  }
  
  static var mockBarcodePositionsCase3: String {
    """
    [
      {
        "rtlsOptionsId": 74,
        "shelfId": 20111,
        "shelfTierId": 48588,
        "shelfTierPosition": 5,
        "itemPositionX": 33.53869897997127,
        "itemPositionY": 68.48717115152746,
        "itemPositionOffsetX": 0.9025812149047852,
        "itemPositionOffsetY": -0.430519700050354,
        "barcode": "7313130215910"
      },
      {
        "rtlsOptionsId": 74,
        "shelfId": 20113,
        "shelfTierId": 48584,
        "shelfTierPosition": 18,
        "itemPositionX": 33.14517859644789,
        "itemPositionY": 67.66215872379578,
        "itemPositionOffsetX": 0.9025812149047852,
        "itemPositionOffsetY": -0.430519700050354,
        "barcode": "7313130215910"
      }
    ]
    """
  }
}
