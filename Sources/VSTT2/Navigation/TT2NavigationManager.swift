//
// TT2NavigationManager
// VSTT2
//
// Created by Hripsime on 2022-01-21
// Copyright Virtual Stores - 2022

import Foundation
import VSFoundation
import Combine
import UIKit

final public class TT2NavigationManager: TT2Navigation {
    public var navigationSpacePublisher: CurrentValueSubject<[NavigationSpace]?, TT2NavigationError> = .init(nil)

    @Inject var downloadManager: DownloadManager
    @Inject var shelfGroupService: ShelfGroupService
    @Inject var storesListService: StoresListService

    private var navigationDataReadyPublisher: CurrentValueSubject<Bool?, Never> = .init(nil)
    private var navigationSpaces = [NavigationSpace]()
    private var navigation: NavigationData?

    private var cancellable: AnyCancellable?
    private var navigationDataCancellable: AnyCancellable?

    init() {}

    deinit {
        navigationDataCancellable?.cancel()
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
                        //add mapZoneUrl

                        if let mapOffsetsUrl = rtlsOption.mapOffsetsUrl, let url = URL(string: mapOffsetsUrl) {
                            offsetZones =  try await downloadManager.downloadData(from: url)
                        }

                        //URL(tryPercentEncoding: rtls.navGraphUrl)
                        if let navGraphUrl = rtlsOption.navGraphUrl, let navgraphUrl = URL(string: navGraphUrl) {
                            navgraph = try await downloadManager.downloadData(from: navgraphUrl)
                        }

                        navigationDataCancellable = navigationDataReadyPublisher
                            .sink(receiveValue: { [weak self] isReady in
                                guard isReady == true, let navgraph = navgraph else { return }

                                self?.navigation = NavigationData(storeId: store.id, rtls: rtlsOption)

                                self?.createNavigationSpace(for: store, rtlsOption: rtlsOption, mapfence: mapfence, navgraph: navgraph, offsetZones: offsetZones, mapZones: mapZones, mapZonePoints: mapZonePoints)
                            })
                    }

                    navigationSpacePublisher.send(navigationSpaces)
                } catch {
                    Logger.init(verbosity: .debug).log(message: error.localizedDescription)
                }
            }
        }
    }

    private func createNavigationInfo(with clientId: Int64, store: Store, floorLevel: Int, mapUrl: URL) {
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
            }, receiveValue: { [weak self] shelfData, storeList in
                let shelfGroups = shelfData.map({ ShelfGroupDto.toShelfGroup($0) })

                if let store = storeList.stores.first(where: { $0.id == store.id }), let rtls = store.rtlsOptions.first(where: { $0.floorLevel == floorLevel }) {
                    let map = Map(id: store.id, mapURL: rtls.mapBoxUrl ?? "", storeId: store.id, railScale: 0, pixelOffsetX: Int(rtls.startOffsetY), pixelOffsetY: Int(rtls.startOffsetY), pixelWidth: Int(rtls.getWidth), pixelHeight: Int(rtls.getHeight))

                    self?.navigation?.map = map
                    self?.navigation?.shelfGroups = shelfGroups
                    self?.navigationDataReadyPublisher.send(true)
                }
            })
    }

    private func createNavigationSpace(for store: Store, rtlsOption: RtlsOptions, mapfence: Data?, navgraph: Data, offsetZones: Data?, mapZones: [MapZone], mapZonePoints: [MapZonePoint]) {
        let startCodes: [PositionedCode] = store.getCodesFor(type: .start, floorLevel: rtlsOption.floorLevel)
        let stopCodes: [PositionedCode] = store.getCodesFor(type: .stop, floorLevel: rtlsOption.floorLevel)
        
        let choosenUrl = rtlsOption.mapBoxUrl ?? rtlsOption.mapBoxImageUrl //tryPercentEncoding

        guard let navigation = navigation, let choosenUrl = choosenUrl, let mapUrl = URL(string: choosenUrl) else { return }

        let mapType = MapType.url(mapUrl)

        let navigationSpace = NavigationSpace(id: rtlsOption.id, name: rtlsOption.name ?? store.name, floorLevel: rtlsOption.floorLevel, mapType: mapType, mapfence: mapfence, mapFenceImage: nil, navgraph: navgraph, offsetZones: offsetZones, mapZones: mapZones, mapZonePoints: mapZonePoints, size: CGSize(width: rtlsOption.getWidth, height: rtlsOption.getHeight), startCodes: startCodes, stopCodes: stopCodes, navigation: navigation)

        navigationSpaces.append(navigationSpace)
    }
}
