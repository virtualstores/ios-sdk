//
// NavigationData
// VSTT2
//
// Created by Hripsime on 2022-01-24
// Copyright Virtual Stores - 2022

import Foundation

public class NavigationData {
    let storeId: Int64
    let rtls: RtlsOptions

    var shelfGroups: [ShelfGroup] = []
    var shelfTierItemPositions: [Int64: ItemPosition] = [:]
    var navigationSpaces: [NavigationSpace] = []
    var map: Map?

    public init(storeId: Int64, rtls: RtlsOptions) {
        self.storeId = storeId
        self.rtls = rtls
    }
}
