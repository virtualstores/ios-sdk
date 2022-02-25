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

    public var positionBundlePublisher: CurrentValueSubject<PositionBundle?, PositionKitError> = .init(nil)
    
    private var cancellable = Set<AnyCancellable>()
    private var publisherCancellable: AnyCancellable?
    private var positionBundleCancellable: AnyCancellable?
    public var positionKitManager: PositionManager
    private var map: IMapController?
    private var location: TT2Location?
    private var analyticseManager: TT2AnalyticsManager?
    
    public init(positionManager: PositionManager) {
        self.positionKitManager = positionManager
    }
    
    public func setupMap(map: IMapController?) {
        self.map = map
    }
    
    public func setupAnalyticsManager(manager: TT2AnalyticsManager) {
        self.analyticseManager = manager
    }

    private func bindPublishers() {
        positionBundleCancellable = positionKitManager.positionPublisher
            .compactMap{ $0 }
            .sink { [weak self] error in
                self?.positionBundlePublisher.send(completion: error)
            } receiveValue: { [weak self] positionBundle in
                self?.positionBundlePublisher.send(positionBundle)
                DispatchQueue.main.async {
                    self?.analyticseManager?.onNewPositionBundle(point: positionBundle.position)
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
}
