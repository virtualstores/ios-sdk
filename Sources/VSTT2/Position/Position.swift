//
// Position
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation

public class Position {
    @Inject var activeShelfGroups: GetActiveShelfGroupsUseCase
    @Inject var getPositionByBarcodeUseCase: GetPositionByBarcodeUseCase
    
    func setup() {
        getPositionByBarcodeUseCase.itemsRepository.reset()
    }
}

extension Position: IPosition {
  var shelfGroups: [ShelfGroup]? { get throws { try activeShelfGroups.invoke() } }

  public func getBy(shelfName: String, completion: @escaping (Result<ItemPosition, Error>) -> ()) {
    var position: ItemPosition?
    do {
      try shelfGroups?.forEach { (shelfGroup) in
        guard position == nil else { return }
        position = shelfGroup.shelves.first(where: { $0.name == shelfName })?.itemPosition
      }
    } catch {
      DispatchQueue.main.async { completion(.failure(error)) }
    }

    DispatchQueue.main.async {
      guard let position = position else { completion(.failure(TT2Error.noShelfFound)); return }
      completion(.success(position))
    }
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
}
