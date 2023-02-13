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
    @Inject var itemPositionService: ItemPositionService
    @Inject var getPositionByBarcodeUseCase: GetPositionByBarcodeUseCase

    private var shelfTierItemPositions: [Int64: ItemPosition] = [:]
    public internal(set) var shelfGroups: [ShelfGroup]?
    private var config: EnvironmentConfig?
    var store: Store?
    private var cancellable = Set<AnyCancellable>()
    
    public init() {}
    
    func setup(with shelfGroups: [ShelfGroup], config: EnvironmentConfig, store: Store) {
        self.shelfGroups = shelfGroups
        for group in shelfGroups {
            for shelf in group.shelves {
                for tier in shelf.shelfTiers {
                    self.shelfTierItemPositions[tier.id] = shelf.itemPosition
                }
            }
        }

        self.config = config
        self.store = store
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

    @available(*, deprecated, message: "Use -getBy(barcode: String, completion: @escaping (Result<Item, Error>) -> ())")
    public func getBy(barcode: String, completion: @escaping (Item?) -> ()) {
        getPositionByBarcodeUseCase.invoke(barcode: barcode) { (result) in
          switch result {
          case .success(let item): completion(item)
          case .failure(_): completion(nil)
          }
        }
    }

    public func getBy(barcode: String, completion: @escaping (Result<Item, Error>) -> ()) {
        getPositionByBarcodeUseCase.invoke(barcode: barcode, completion: completion)
    }

    @available(*, deprecated, message: "Use -getBy(barcodes: [String], completion: @escaping (Result<[Item], Error>) -> ())")
    public func getBy(barcodes: [String], completion: @escaping ([Item]) -> ()) {
        let group = DispatchGroup()
        var positions: [Item] = []

        group.enter()
        barcodes.forEach { (barcode) in
            getBy(barcode: barcode) { data in
                if let data = data {
                    positions.append(data)
                }
                if let last = barcodes.last, barcode == last {
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            DispatchQueue.main.async { completion(positions) }
        }
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
              completion(.failure(NSError()))
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
