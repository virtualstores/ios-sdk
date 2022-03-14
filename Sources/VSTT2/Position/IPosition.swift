//
// IPosition
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import Combine

public protocol IPosition {
    /// Method will return ItemPosition for shelfName
    func getBy(shelfName: String, completion: @escaping (ItemPosition) -> ())
    
    /// Method will return Item for barcode
    func getBy(barcode: String, completion: @escaping ([BarcodePosition]?) -> ())
    
    /// Method will return Items for barcodes
    func getBy(barcodes: [String], completion: @escaping ([String : [BarcodePosition]]) -> ())
}
