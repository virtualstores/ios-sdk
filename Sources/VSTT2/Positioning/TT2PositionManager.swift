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

final public class TT2PositionManager: TT2Positioning {
    @Inject var mapFenceDataService: MapFenceDataService

    private var cancellable = Set<AnyCancellable>()
    private var publisherCancellable: AnyCancellable?
    private var positionBundleCancellable: AnyCancellable?
    private var positionKitManager: PositionManager

    public var stepCountPublisher: CurrentValueSubject<Int, Never> = .init(0)
    public var positionBundlePublisher: CurrentValueSubject<PositionBundle?, PositionKitError> = .init(nil)

    public init(positionManager: PositionManager) {
        self.positionKitManager = positionManager
    }

    private func bindPublishers() {
        publisherCancellable = positionKitManager.stepCountPublisher
            .sink { [weak self] error in
                self?.stepCountPublisher.send(completion: error)
            } receiveValue: { [weak self]  data in
                self?.stepCountPublisher.send(data)
            }

        positionBundleCancellable = positionKitManager.positionPublisher
            .sink { [weak self] error in
                self?.positionBundlePublisher.send(completion: error)
            } receiveValue: { [weak self]  positionBundle in
                self?.positionBundlePublisher.send(positionBundle)
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
            // self.validateSession(forStore: activeStore.store.id)
        } else {
            synchronize(code: code, syncDirection: syncDirection)
            //  self.validateSession(forStore: activeStore.store.id)
        }
    }

    func stopUpdatingLocation(saveRecording: Bool = false, uploadRecording: Bool = false) {
        positionKitManager.stop()

        //        if uploadRecording {
        //            self.sendData(firstName: nil, lastName: nil, route: nil, gender: nil, age: nil, comments: nil)
        //        } else {
        //            self.debugTools?.showMap()
        //        }
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
}

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
                do {
                    try self?.positionKitManager.setupMapFence(with: data)
                    self?.positionKitManager.startNavigation(with: 180, xPosition: 4.570476, yPosition: 2.094637)
                } catch {
                    // Add error handling logic when MapFence setup failed
                }
            }).store(in: &cancellable)
    }
}
