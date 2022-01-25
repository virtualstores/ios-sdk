//
// NavigationData
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation

public final class NavigationData {
    private let storeId: Int64
    private let rtls: RtlsOptions

    var shelfTierItemPositions: [Int64: ItemPosition] = [:]
    var shelfGroups: [ShelfGroup] = []
    var navigationSpaces: [NavigationSpace] = []
    var map: Map?

    public init(storeId: Int64, rtls: RtlsOptions) {
        self.storeId = storeId
        self.rtls = rtls
    }
    
    public func getItemPosition(with shelfTierId: Int64) -> ItemPosition? {
        return shelfTierItemPositions[shelfTierId]
    }
}
