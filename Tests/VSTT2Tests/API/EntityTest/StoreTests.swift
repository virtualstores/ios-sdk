//
// StoreTests
// VSTT2
//
// Created by Hripsime on 2021-12-28
// Copyright Virtual Stores - 2021

import XCTest
//@testable import VSEngineWrapper
import VSTT2

extension String {
    static var storeFixture: String {
        """
        {
          "stores": [
            {
              "id": 4,
              "externalId": "string",
              "clientId": 0,
              "name": "name",
              "longitude": 10,
              "latitude": 45,
              "supportedVersionCode": "string",
              "minIosVersion": "string",
              "minAndroidVersion": "string",
              "active": true,
              "rtlsOptions": {
                "id": 6,
                "isDefault": true,
                "width": 100,
                "height": 70,
                "widthInMeters": 20.2,
                "heightInMeters": 30.3,
                "pixelsPerMeter": 0,
                "startOffsetX": 6,
                "startOffsetY": 7,
                "waitTime": 0,
                "floorLevel": 21,
                "north": 0,
                "panId": "string",
                "name": "store name",
                "mapBoxUrl": "http://mapBoxUrl.se",
                "mapBoxStyleUrl": "http://mapBoxStyleUrl.se",
                "mapBoxImageUrl": "http://mapBoxImageUrl.se",
                "mapBoxToken": "mapBoxToken",
                "mapFenceUrl": "http://mapFenceUrl.se",
                "mapZonesUrl": "http://mapZonesUrl.se",
                "navGraphUrl": "http://navGraphUrl.se",
                "mapOffsetsUrl": "http://mapOffsetsUrl.se",
                "mapDataVersionUrl": "http://mapDataVersionUrl.se",
                "categoryZonesUrl": "http://categoryZonesUrl.se",
                "scanLocations": [
                  {
                    "id": 0,
                    "code": "string",
                    "x": 0,
                    "y": 0,
                    "direction": 0,
                    "isRouteLocation": true,
                    "type": 0
                  }
                ]
              },
              "address": {
                "city": "Stockholm",
                "zipCode": "0054",
                "address": "Address 1",
                "description": "description text"
              },
              "serverConnection": {
                "apiKey": "string",
                "serverAddress": "string",
                "mqttAddress": "string",
                "storeId": 0
              },
              "statServerConnection": {
                "apiKey": "string",
                "serverAddress": "string",
                "mqttAddress": "string",
                "storeId": 0
              },
              "smileyServerConnection": {
                "apiKey": "string",
                "serverAddress": "string",
                "mqttAddress": "string",
                "storeId": 0
              },
              "rtlsOptionsList": [
                {
                  "id": 6,
                  "isDefault": true,
                  "width": 100,
                  "height": 70,
                  "widthInMeters": 20.2,
                  "heightInMeters": 30.3,
                  "pixelsPerMeter": 0,
                  "startOffsetX": 6,
                  "startOffsetY": 7,
                  "waitTime": 0,
                  "floorLevel": 21,
                  "north": 0,
                  "panId": "string",
                  "name": "store name",
                  "mapBoxUrl": "http://mapBoxUrl.se",
                  "mapBoxStyleUrl": "http://mapBoxStyleUrl.se",
                  "mapBoxImageUrl": "http://mapBoxImageUrl.se",
                  "mapBoxToken": "mapBoxToken",
                  "mapFenceUrl": "http://mapFenceUrl.se",
                  "mapZonesUrl": "http://mapZonesUrl.se",
                  "navGraphUrl": "http://navGraphUrl.se",
                  "mapOffsetsUrl": "http://mapOffsetsUrl.se",
                  "mapDataVersionUrl": "http://mapDataVersionUrl.se",
                  "categoryZonesUrl": "http://categoryZonesUrl.se",
                  "scanLocations": [
                    {
                      "id": 0,
                      "code": "string",
                      "x": 6,
                      "y": 7,
                      "direction": 0,
                      "isRouteLocation": true,
                      "type": 0
                    }
                  ]
                }
              ],
              "devices": [
                {
                  "macAddress": "string",
                  "name": "string",
                  "storeId": 0
                }
              ],
              "supportedPayMethods": [
                0
              ],
              "startScanLocations": [
                {
                  "id": 3,
                  "code": "123",
                  "x": 12,
                  "y": 21,
                  "direction": 0,
                  "isRouteLocation": true,
                  "type": 0
                }
              ],
              "stopScanLocations": [
                {
                  "id": 0,
                  "code": "string",
                  "x": 0,
                  "y": 0,
                  "direction": 0,
                  "isRouteLocation": true,
                  "type": 0
                }
              ]
            }
          ]
        }
        """
    }
}

final class StoreTests: XCTestCase {
    func test_encodinge_valide_data() {
        guard let jsonData = String.storeFixture.data(using: .utf8), let store: StoresList = try? JSONDecoder().decode(StoresList.self, from: jsonData) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(store.stores.count, 1)
        XCTAssertEqual(store.stores.first?.id, 4)
        XCTAssertEqual(store.stores.first?.name, "name")
        XCTAssertEqual(store.stores.first?.address.city, "Stockholm")
        XCTAssertEqual(store.stores.first?.address.zipCode, "0054")
        XCTAssertEqual(store.stores.first?.address.address, "Address 1")
        XCTAssertEqual(store.stores.first?.address.description, "description text")
        XCTAssertEqual(store.stores.first?.latitude, 45)
        XCTAssertEqual(store.stores.first?.longitude, 10)
        XCTAssertEqual(store.stores.first?.active, true)
        XCTAssertEqual(store.stores.first?.startCodes.count, 1)
        XCTAssertEqual(store.stores.first?.startCodes.first?.code, "123")
        XCTAssertEqual(store.stores.first?.startCodes.first?.xPosition, 12)
        XCTAssertEqual(store.stores.first?.startCodes.first?.yPosition, 21)
        XCTAssertEqual(store.stores.first?.startCodes.first?.direction, 0)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.id, 6)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.width, 100)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.height, 70)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.widthInMeters, 20.2)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.heightInMeters, 30.3)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.floorLevel, 21)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.north, 0)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.name, "store name")
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.startOffsetX, 6)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.startOffsetY, 7)
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.mapBoxUrl, "http://mapBoxUrl.se")
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.mapBoxToken, "mapBoxToken")
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.mapFenceUrl, "http://mapFenceUrl.se")
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.mapZonesUrl, "http://mapZonesUrl.se")
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.navGraphUrl, "http://navGraphUrl.se")
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.mapOffsetsUrl, "http://mapOffsetsUrl.se")
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.mapDataVersionUrl, "http://mapDataVersionUrl.se")
        XCTAssertEqual(store.stores.first?.rtlsOptions.first?.mapBoxImageUrl, "http://mapBoxImageUrl.se")
    }
}
