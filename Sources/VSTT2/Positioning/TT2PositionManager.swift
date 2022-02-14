//
// TT2PositionManager
// VSTT2
//
// Created by Hripsime on 2022-01-11.
// Copyright Virtual Stores - 2021

import Foundation
import Combine
import VSFoundation
import VSPositionKit
import CoreGraphics
import UIKit

final public class TT2PositionManager: TT2Positioning {
    @Inject var mapFenceDataService: MapFenceDataService

    private var cancellable = Set<AnyCancellable>()
    private var publisherCancellable: AnyCancellable?
    private var positionBundleCancellable: AnyCancellable?
    private var positionKitManager: PositionManager
    private var map: IMap?
    private var location: TT2Location?
    private var currentMapFence: MapFence?
    public var positionBundlePublisher: CurrentValueSubject<PositionBundle?, PositionKitError> = .init(nil)
    public var mapFanceDataExistPublisher: CurrentValueSubject<Bool?, Never> = .init(nil)

    public init(positionManager: PositionManager) {
        self.positionKitManager = positionManager
    }
    
    public func setupMap(map: IMap?) {
        self.map = map
    }

    private func bindPublishers() {
        positionBundleCancellable = positionKitManager.positionPublisher
            .compactMap{ $0 }
            .sink { [weak self] error in
                self?.positionBundlePublisher.send(completion: error)
            } receiveValue: { [weak self]  positionBundle in
                self?.positionBundlePublisher.send(positionBundle)
                DispatchQueue.main.async {
                    self?.map?.updateUserLocation(newLocation: positionBundle.position, std: positionBundle.std ?? 0.0)
                }
            }
    }
}

public extension TT2PositionManager {
    func startUpdatingLocation(_ location: TT2Location) throws {
        try positionKitManager.start()
        
        positionKitManager.startNavigation(with: location.course.degrees,
                                           xPosition: location.position.xPosition,
                                           yPosition: location.position.yPosition)

        bindPublishers()
    }

    func startUpdatingLocation(with code: PositionedCode, offset: Double? = nil, syncDirection: Bool = false) {
        if let offset = offset {
            let dir = code.direction + offset
            let code = PositionedCode(code: code.code, xPosition: code.xPosition, yPosition: code.yPosition, direction: dir, type: code.type)
            synchronize(code: code, syncDirection: syncDirection)
        } else {
            synchronize(code: code, syncDirection: syncDirection)
        }
    }

    func stopUpdatingLocation(saveRecording: Bool = false, uploadRecording: Bool = false) {
        positionKitManager.stop()
    }

    func synchronize(code: PositionedCode, syncDirection: Bool = false) {
        let location = TT2Location(position: TT2Position(point: code.point, offset: CGPoint(x: 0.0, y: 0.0)),
                                   course: TT2Course(fromDegrees: code.direction), syncDirection: syncDirection)
        do {
            try startUpdatingLocation(location)
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "StartUpdatingLocation error")
        }
    }

    func configureStoreData(for store: Store, floorLevel: Int?) {
        guard let url = store.rtlsOptions.first?.mapFenceUrl else { return }
        
        self.getMapFenceData(with: url)
    }
    
    func createMapData(rtlsOptions: RtlsOptions) -> MapData? {
        guard let mapFance = currentMapFence else { return nil }
        
        let coordinateConverter = BaseCoordinateConverter(heightInPixels: mapFance.properties.height, widthInPixels: mapFance.properties.width, pixelPerMeter: rtlsOptions.pixelsPerMeter, pixelPerLatitude: 1000.0)
        let mapData = MapData(rtlsOptions: rtlsOptions, style: MapStyle(), converter: coordinateConverter)
        
        return mapData
    }
}

//before positioning setup
extension TT2PositionManager {
    private func getMapFenceData(with url: String) {
        let parameters = MapFenceDataParameters(url: url)
        mapFenceDataService
            .call(with: parameters)
            .sink(receiveCompletion: { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            }, receiveValue: { [weak self] (data) in
                guard let self = self else { return }
                
                self.currentMapFence = data
                self.positionKitManager.setupMapFence(with: data)
                self.mapFanceDataExistPublisher.send(true)
            }).store(in: &cancellable)
    }
}
