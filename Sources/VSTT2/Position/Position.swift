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

    private var shelfTierItemPositions: [Int64: ItemPosition] = [:]
    private var shelfGroups: [ShelfGroup]?
    private var config: EnvironmentConfig?
    private var storeId: Int64?
    private var barcodePositions: [String : [BarcodePosition]] = [:]
    private var cancellable = Set<AnyCancellable>()
    
    public init() {}
    
    func setup(with shelfGroups: [ShelfGroup], config: EnvironmentConfig, storeId: Int64) {
        self.shelfGroups = shelfGroups
        for group in shelfGroups {
            for shelf in group.shelves {
                for tier in shelf.shelfTiers {
                    self.shelfTierItemPositions[tier.id] = shelf.itemPosition
                }
            }
        }

        self.config = config
        self.storeId = storeId
    }
    
    public func getBy(shelfName: String, completion: @escaping (ItemPosition) -> ()) {
        var position: ItemPosition?
        shelfGroups?.forEach { shelfGroup in
            if let shelf = shelfGroup.shelves.first(where: { $0.name == shelfName }) {
                position = shelf.itemPosition
            }
        }
        
        guard let itemPosition = position else { return }
        
        completion(itemPosition)
    }

    public func getBy(barcode: String, completion: @escaping ([BarcodePosition]?) -> ()) {
        guard let storeId = storeId else { return }

        if let barcodePosition = barcodePositions[barcode] {
            completion(barcodePosition)
        } else {
            itemPositionService
                .call(with: ItemPositionParameters(storeId: storeId, barcode: barcode, config: config))
                .sink { (subscriberCompletion) in
                    switch subscriberCompletion {
                    case .finished: break
                    case .failure(let error):
                        Logger(verbosity: .debug).log(message: error.localizedDescription)
                        completion(nil)
                    }
                } receiveValue: { [weak self] (data) in
                  self?.barcodePositions[barcode] = data
                  completion(data)
                }.store(in: &cancellable)
        }
    }

    public func getBy(barcodes: [String], completion: @escaping ([String : [BarcodePosition]]) -> ()) {
        let group = DispatchGroup()
        var positions: [String : [BarcodePosition]] = [:]

        group.enter()
        barcodes.forEach { (barcode) in
            self.getBy(barcode: barcode) { data in
                positions[barcode] = data
                if let last = barcodes.last, barcode == last {
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(positions)
        }
    }
}
