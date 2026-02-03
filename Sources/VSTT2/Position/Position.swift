//
// Position
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Combine
import Foundation
import VSFoundation

public class Position {
    @Inject var activeShelfGroups: GetActiveShelfGroupsUseCase
    @Inject var getPositionByBarcodeUseCase: GetPositionByBarcodeUseCase

    private var cancellables: Set<AnyCancellable> = []

    deinit {
      dispose()
    }

    public func dispose() {
      cancellables.removeAll()
    }

    func setup() {
        getPositionByBarcodeUseCase.itemsRepository.reset()
    }
}

extension Position: IPosition {
  var shelfGroups: [ShelfGroup]? { get throws { try activeShelfGroups.invoke() } }

  public func getBy(shelfName: String) -> AnyPublisher<ItemPosition, Error> {
    .justOrFail {
      guard
        let position = try shelfGroups?.lazy
          .compactMap({ $0.shelves.first(where: { $0.name == shelfName })?.itemPosition })
          .first
      else { throw TT2Error.noShelfFound }
      return position
    }
    .receive(on: DispatchQueue.main)
    .eraseToAnyPublisher()
  }

  public func getBy(barcode: String) -> AnyPublisher<Item, Error> {
    getPositionByBarcodeUseCase.invoke(barcode: barcode)
  }

  public func getBy(barcodes: [String]) -> AnyPublisher<[Item], Error> {
    Publishers.MergeMany(barcodes.map { getBy(barcode: $0) })
      .collect()
      .eraseToAnyPublisher()
  }

  public func getBy(identifier: String) -> AnyPublisher<Item, Error> {
    getBy(shelfName: identifier)
      .map { $0.asItem }
      .catch { [weak self] (error) in
        self?.getBy(barcode: identifier) ?? .fail(with: error)//.fail(with: NSError(domain: "No position found", code: -1))
      }
      .eraseToAnyPublisher()
  }

  public func getBy(shelfName: String, completion: @escaping (Result<ItemPosition, Error>) -> ()) {
    getBy(shelfName: shelfName)
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }

  public func getBy(barcode: String, completion: @escaping (Result<Item, Error>) -> ()) {
    getBy(barcode: barcode)
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }

  public func getBy(barcodes: [String], completion: @escaping (Result<[Item], Error>) -> ()) {
    getBy(barcodes: barcodes)
      .asResult()
      .sink(receiveValue: completion)
      .store(in: &cancellables)
  }
}

extension ItemPosition {
  var asItem: Item { .init(name: identifier, externalId: identifier, itemPositions: [self]) }
}
