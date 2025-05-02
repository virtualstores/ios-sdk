//
//  StoreApi.swift
//  
//
//  Created by Théodore Roos on 2022-12-15.
//

import Foundation
import VSFoundation

class MockStoreApi {}

extension MockStoreApi: IStoreApi {
  func fetchStores(clientId: Int64, completion: @escaping (Result<[Store], Error>) -> Void) {
    completion(.success([.init(
      id: 93,
      externalId: nil,
      clientId: 1,
      name: "Mock Store",
      address: .init(city: nil, zipCode: nil, address: nil, description: nil),
      latitude: 0.0,
      longitude: 0.0,
      active: true,
      hasSensorRecordingActive: true,
      hasWiFiRecordingActive: true,
      startCodes: [],
      stopCodes: [],
      rtlsOptions: [.init(
        id: 1,
        widthInMeters: 10,
        heightInMeters: 10,
        floorLevel: nil,
        north: 0.0,
        name: "Mock Floorlevel",
        startOffsetX: 0,
        startOffsetY: 0,
        mapBoxUrl: nil,
        mapBoxToken: nil,
        mapFenceUrl: "https://example.com/",
        mapZonesUrl: "https://example.com/",
        navGraphUrl: "https://example.com/",
        mapOffsetsUrl: nil,
        mapDataVersionUrl: nil,
        mapBoxImageUrl: nil,
        pixelsPerMeter: 50.0,
        boundingBoxInMeters: nil,
        scanLocations: [
          .init(code: "Mock_Start", xPosition: 1.0, yPosition: 1.0, direction: 0.0, isRouteLocation: true, type: .start),
          .init(code: "Mock_Stop", xPosition: 2.0, yPosition: 2.0, direction: 0.0, isRouteLocation: true, type: .stop)
        ],
        isDefault: true
      )],
      minVersion: nil,
      serverConnection: nil,
      statServerConnection: .init(apiKey: nil, serverAddress: nil),
      positionServiceSettings: .init(
        useML: false,
        useCoefficientOptimizer: false,
        useDriftCompensator: false,
        boolValues: ["ios_magnetometerDriftEstimatorParams_useMagnetometer": true],
        stringValues: nil,
        stringArrayValues: nil,
        intValues: nil,
        intArrayValues: nil,
        floatValues: [
          "ios_magnetometerDriftEstimatorParams_maxRate": 0.025,
          "ios_magnetometerDriftEstimatorParams_alpha": 0.99995,
          "ios_magnetometerDriftEstimatorParams_accLowerLimit": 0.8,
          "ios_magnetometerDriftEstimatorParams_accUpperLimit": 15,
          "ios_magnetometerDriftEstimatorParams_sigmaMag": 30,
          "ios_magnetometerDriftEstimatorParams_magExpectedNorm": 49.4
        ],
        floatArrayValues: nil
      ),
      syncPositionFilter: nil,
      syncCompassFilter: nil,
      acceptedScoreLimit: 500
    )]))
  }

  func fetchSwapLocations(storeId: Int64, completion: @escaping (Result<[SwapLocation], Error>) -> ()) {
    completion(.success([]))
  }
}
