//
// IPosition
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import VSFoundation

public protocol IPosition: Disposable {
    /// Method will return ItemPosition for shelfName
    func getBy(shelfName: String) -> AnyPublisher<ItemPosition, Error>
    @available(*, deprecated, renamed: "getBy(shelfName:)", message: "Please use the updated Combine version")
    func getBy(shelfName: String, completion: @escaping (Result<ItemPosition, Error>) -> ())

    /// Method will return Item for barcode
    func getBy(barcode: String) -> AnyPublisher<Item, Error>
    @available(*, deprecated, renamed: "getBy(barcode:)", message: "Please use the updated Combine version")
    func getBy(barcode: String, completion: @escaping (Result<Item, Error>) -> ())

    /// Method will return Items for barcodes
    func getBy(barcodes: [String]) -> AnyPublisher<[Item], Error>
    @available(*, deprecated, renamed: "getBy(barcodes:)", message: "Please use the updated Combine version")
    func getBy(barcodes: [String], completion: @escaping (Result<[Item], Error>) -> ())

    /// Convenience method that calls **getBy(shelfName:)**. If it's nil, it will call **getBy(barcode:)**
    func getBy(identifier: String) -> AnyPublisher<Item, Error>
}
