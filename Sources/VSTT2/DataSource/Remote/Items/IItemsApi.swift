//
//  IItemsApi.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation

protocol IItemsApi {
  func getBy(storeId: Int64, barcode: String, completion: @escaping (Result<[BarcodePosition], Error>) -> ())
}
