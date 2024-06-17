//
// Position
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import VSFoundation

public class Position: IPosition {
    @Inject var activeStore: GetActiveStoreUseCase
    @Inject var activeShelfGroups: GetActiveShelfGroupsUseCase
    @Inject var getPositionByBarcodeUseCase: GetPositionByBarcodeUseCase

    public var shelfGroups: [ShelfGroup]? { activeShelfGroups.invoke() }

    private var shelfTierItemPositions: [Int64: ItemPosition] = [:]
    private var store: Store { activeStore.invoke() }
    private var cancellable = Set<AnyCancellable>()
    
    public init() {}
    
    func setup(with shelfGroups: [ShelfGroup], store: Store) {
        shelfGroups.forEach { (group) in
            group.shelves.forEach { (shelf) in
                shelf.shelfTiers.forEach { (tier) in
                    self.shelfTierItemPositions[tier.id] = shelf.itemPosition
                }
            }
        }

        getPositionByBarcodeUseCase.itemsRepository.reset()
    }
    
    public func getBy(shelfName: String, completion: @escaping (ItemPosition?) -> ()) {
        var position: ItemPosition?
        shelfGroups?.forEach { shelfGroup in
            if let shelf = shelfGroup.shelves.first(where: { $0.name == shelfName }) {
                position = shelf.itemPosition
            }
        }
        
        DispatchQueue.main.async { completion(position) }
    }

    public func getBy(barcode: String, completion: @escaping (Result<Item, Error>) -> ()) {
        getPositionByBarcodeUseCase.invoke(barcode: barcode, completion: completion)
    }

    public func getBy(barcodes: [String], completion: @escaping (Result<[Item], Error>) -> ()) {
      let group = DispatchGroup()
      var items: [Item] = []
      var savedError: Error?

      group.enter()
      barcodes.forEach { (barcode) in
        getBy(barcode: barcode) { (result) in
          switch result {
          case .success(let item): items.append(item)
          case .failure(let error): savedError = error
          }
          if let last = barcodes.last, barcode == last {
              group.leave()
          }
        }
      }

      group.notify(queue: .main) {
        DispatchQueue.main.async {
          if items.isEmpty {
            if let error = savedError {
              completion(.failure(error))
            } else {
              completion(.failure(NSError(domain: "No positions found", code: 400)))
            }
          } else {
            completion(.success(items))
          }
        }
      }
    }
    
    deinit {
        cancellable.removeAll()
    }
}
