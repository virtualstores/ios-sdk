//
//  File.swift
//
//
//  Created by Hripsime on 2022-01-13.
//

import Foundation
import VSFoundation
import Combine

final public class TT2AnalyticsManager: TT2Analytics {
    @Inject var createVisitsService: CreateVisitsService

    private let store: Store
    private var timeFormatter: DateFormatter = DateFormatter()
    private var cancellable = Set<AnyCancellable>()

    init(store: Store) {
        self.store = store

        self.timeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    }

    public func startVisit(deviceInformation: DeviceInformation, tags: [String: String] = [:], metaData: [String: String] = [:]) {
        let date = self.timeFormatter.string(from: Date())
        let parameters = CreateVisitsParameters(apiKey: store.serverConnection.apiKey,
                                                requestId: UUID().uuidString.uppercased(),
                                                storeId: store.id,
                                                start: date,
                                                stop: date,
                                                deviceInformation: deviceInformation,
                                                tags: tags,
                                                metaData: metaData)
        createVisitsService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(): break
                    // Publish error
                }
            }, receiveValue: { (_) in
                // Publish data
            }).store(in: &cancellable)
    }

    public func startCollectingHeatMapData() throws {}

    public func stopCollectingHeatMapData() {}

    public func stopVisit() {}
}
