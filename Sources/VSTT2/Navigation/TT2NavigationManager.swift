//
// TT2NavigationManager
// VSTT2
//
// Created by Hripsime on 2022-01-21
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine
import CoreGraphics

final public class TT2NavigationManager: TT2Navigation {
    public var navigationSpacePublisher: CurrentValueSubject<[NavigationSpace]?, TT2NavigationError> = .init(nil)

    @Inject var downloadManager: DownloadManager
    @Inject var shelfGroupService: ShelfGroupService
    @Inject var storesListService: StoresListService

    private var navigationSpaces = [NavigationSpace]()
    private var cancellable: AnyCancellable?

    init() {}

    deinit {
        cancellable?.cancel()
    }
}

extension TT2NavigationManager {
    func prepareNavigationSpace(for store: Store) {
        if #available(iOS 15.0.0, *) {
            Task.init {
                do {
                    for rtlsOption in store.rtlsOptions {
                         var mapfence: Data?
                         var navgraph: Data?
                         var offsetZones: Data?
                         let mapZones: [MapZone] = []
                         let mapZonePoints: [MapZonePoint] = []

                        if let mapFenceUrl = rtlsOption.mapFenceUrl, let url = URL(string: mapFenceUrl) {
                            mapfence = try await downloadManager.downloadData(from: url)
                        }
                        // add mapZoneUrl

                        if let mapOffsetsUrl = rtlsOption.mapOffsetsUrl, let url = URL(string: mapOffsetsUrl) {
                            offsetZones =  try await downloadManager.downloadData(from: url)
                        }

                        // URL(tryPercentEncoding: rtls.navGraphUrl)
                        if let navGraphUrl = rtlsOption.navGraphUrl, let navgraphUrl = URL(string: navGraphUrl) {
                            navgraph = try await downloadManager.downloadData(from: navgraphUrl)
                        }
                        
                        let navigation = self.createNavigationInfo(with: 1, store: store, floorLevel: rtlsOption.floorLevel, rtlsOption: rtlsOption)
                        
                        guard let navgraph = navgraph else { return }
                        
                        self.createNavigationSpace(for: store, rtlsOption: rtlsOption, mapfence: mapfence, navgraph: navgraph, offsetZones: offsetZones, mapZones: mapZones, mapZonePoints: mapZonePoints, navigation: navigation)
                    }

                    navigationSpacePublisher.send(navigationSpaces)
                } catch {
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }
        }
    }

    private func createNavigationInfo(with clientId: Int64, store: Store, floorLevel: Int, rtlsOption: RtlsOptions) -> NavigationData {
        let navigation = NavigationData(storeId: store.id, rtls: rtlsOption)

        let shelfGroupParameters = ShelfGroupParameters(storeId: store.id)
        let parameters = StoresListParameters(clientId: clientId)

        cancellable = Publishers.Zip(
            shelfGroupService.call(with: shelfGroupParameters),
            storesListService.call(with: parameters))
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }, receiveValue: { shelfData, storeList in
                print(storeList.stores.count)
                let shelfGroups = shelfData.map({ ShelfGroupDto.toShelfGroup($0) })

                if let store = storeList.stores.first(where: { $0.id == store.id }), let rtls = store.rtlsOptions.first(where: { $0.floorLevel == floorLevel }) {
                    let map = Map(id: store.id, mapURL: rtls.mapBoxUrl ?? "", storeId: store.id, railScale: 0, pixelOffsetX: Int(rtls.startOffsetY), pixelOffsetY: Int(rtls.startOffsetY), pixelWidth: Int(rtls.rtlsOptionsWidth()), pixelHeight: Int(rtls.rtlsOptionsHeight()))

                    navigation.map = map
                    navigation.shelfGroups = shelfGroups
                }
            })
        
        return navigation
    }

    private func createNavigationSpace(for store: Store, rtlsOption: RtlsOptions, mapfence: Data?, navgraph: Data, offsetZones: Data?, mapZones: [MapZone], mapZonePoints: [MapZonePoint], navigation: NavigationData) {
        let startCodes: [PositionedCode] = store.getCodesFor(type: .start, floorLevel: rtlsOption.floorLevel)
        let stopCodes: [PositionedCode] = store.getCodesFor(type: .stop, floorLevel: rtlsOption.floorLevel)

        let choosenUrl = rtlsOption.mapBoxUrl ?? rtlsOption.mapBoxImageUrl // tryPercentEncoding

        guard let choosenUrl = choosenUrl, let mapUrl = URL(string: choosenUrl) else { return }

        let mapType = MapType.url(mapUrl)

        let navigationSpace = NavigationSpace(id: rtlsOption.id, name: rtlsOption.name ?? store.name, floorLevel: rtlsOption.floorLevel, mapType: mapType, mapfence: mapfence, mapFenceImage: nil, navgraph: navgraph, offsetZones: offsetZones, mapZones: mapZones, mapZonePoints: mapZonePoints, size: CGSize(width: rtlsOption.rtlsOptionsWidth(), height: rtlsOption.rtlsOptionsHeight()), startCodes: startCodes, stopCodes: stopCodes, navigation: navigation)

        navigationSpaces.append(navigationSpace)
    }
}
