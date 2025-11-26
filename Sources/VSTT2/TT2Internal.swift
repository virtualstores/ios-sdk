//
// TT2Internal
// VSTT2
//
// Created by Hripsime on 2021-03-03
// Copyright Virtual Stores - 2022

import Foundation
import Combine
import CoreLocation
import UIKit
import VSFoundation
import VSPositionKit

internal class TT2Internal: Disposable {
    /// Managers for helping VSTT2 to work with separate small modules
    @Inject var analytics: TT2AnalyticsManager
    @Inject var awsS3UploadManager: AWSS3UploadManager
    @Inject var config: EnvironmentConfig
    @Inject var floorManager: VSTT2FloorManager
    @Inject var leaseManager: ILeaseManager
    @Inject var mlModelManager: VSMLModelManager
    @Inject var navigation: Navigation
    @Inject var position: Position
    @Inject var recording: RecordingManager
    @Inject var user: IUserManager

    /// Usecases - Auth
    @Inject var login: LoginUseCase
    @Inject var setAuthSettings: SetAuthSettingsUseCase
    @Inject var setApiKey: SetApiKeyUseCase

    /// Usecases - Client
    @Inject var fetchClient: FetchClientsUseCase
    @Inject var getActiveClient: GetActiveClientUseCase
    @Inject var getCachedClients: GetCachedClientsUseCase
    @Inject var setActiveClient: SetActiveClientUseCase
    /// Usecases - Status
    @Inject var getTT2Settings: GetCurrentTT2SettingsUseCase
    @Inject var isVPSRunning: SubscribeToIsVPSRunningUseCase
    @Inject var isReferenceAngleCertain: SubscribeToIsReferenceAngleCertainUseCase
    @Inject var setGPSPosition: SetGPSPositionUseCase
    @Inject var setVPSPosition: SetVPSPositionUseCase
    @Inject var setTT2Settings: SetTT2SettingsUseCase
    /// Usecases - Store
    @Inject var fetchStore: FetchStoreUseCase
    @Inject var fetchSwapLocations: FetchSwapLocationsUseCase
    @Inject var getActiveStore: GetActiveStoreUseCase
    @Inject var getCachedStore: GetCachedStoreUseCase
    @Inject var getCachedSwapLocations: GetCachedSwapLocationsUseCase
    @Inject var getZonesTree: GetZonesTreeUseCase
    @Inject var setActiveStore: SetActiveStoreUseCase
    /// Usecases - Generic
    @Inject var stopTT2: StopTT2UseCase

    let deviceOrientationUploader: DeviceOrientationUploader = .init()
    var mapManager: IMapManager?
    var mapController: IMapController?
    var wifiController: IWiFiController?

    private let tag = "TT2Internal"
    private var cancellable = Set<AnyCancellable>()
    
    private var offset: Double
    
    var internalClients: [Client] { getCachedClients.invoke() }
    var activeClient: Client? { try? getActiveClient.invoke() }
    var internalStores: [Store] { getCachedStore.invoke(filterOnlyActive: false) }
    var internalStoresActive: [Store] { getCachedStore.invoke() }
    var activeStore: Store? { try? getActiveStore.invoke() }
    var automaticActivationOfUserMark: Bool = true
    var automaticSensorRecording: Bool { activeStore?.hasSensorRecordingActive ?? false }

    init(connectionSettings: EnvironmentConfig.Settings, authSettings: AuthSettings, settings: TT2Settings) {
      offset = 0.0
      config.set(connection: connectionSettings)
      setAuthSettings.invoke(settings: authSettings)
      set(tt2Settings: settings)
      bindPublishers()
    }

    deinit {
      Logger(verbosity: .info).log(message: "\(tag): deinit")
      dispose()
    }

    func dispose() {
      Logger(verbosity: .info).log(message: "\(tag): dispose")
      mapController?.dispose()
      mapController = nil
      mapManager?.dispose()
      mapManager = nil
      cancellable.removeAll()
    }

    func createMapData(rtlsOptions: RtlsOptions, mapFence: MapFence, coordinateConverter: ICoordinateConverter?) -> MapData? {
        guard let converter = coordinateConverter else { return nil }
        return MapData(rtlsOptions: rtlsOptions, converter: converter)
    }

    func getSwapLocations(storeId: Int64) -> AnyPublisher<[SwapLocation], Error> {
        fetchSwapLocations.invoke(storeId: storeId)
            .compactMap { [weak self] in self?.getCachedSwapLocations.invoke() }
            .eraseToAnyPublisher()
    }

    func setActiveStore(storeId: Int64) throws {
        try setActiveStore.invoke(storeId: storeId)
    }

    func set(tt2Settings: TT2Settings) {
        setTT2Settings.invoke(settings: tt2Settings)
    }

    private func bindPublishers() {
        isVPSRunning.invoke()
          .sink { [weak self] (isActive) in
              self?.mapManager?.set(isPositionActive: isActive)
              if isActive {
                  self?.mapController?.reset()
                  if self?.automaticActivationOfUserMark ?? true {
                      self?.mapController?.start()
                  }
              } else {
                  self?.mapController?.stop()
              }
          }.store(in: &cancellable)

        isReferenceAngleCertain.invoke()
            .sink { [weak self] (isReferenceAngleCertain) in
                self?.mapManager?.set(isReferenceAngleCertain: isReferenceAngleCertain)
            }.store(in: &cancellable)

        navigation.onForceSyncPublisher
            .compactMap { $0 }
            .sink { [weak self] (_) in
              self?.mapController?.onForceSync()
            }.store(in: &cancellable)

        navigation.vpsPosition.recordingInputPublisher
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] (identifier, data, sessionId, lastFile) in
                let sessionId = self?.analytics.visitId?.description ?? sessionId
                self?.awsS3UploadManager.prepareDataToSend(identifier: identifier, data: data, folderPath: self?.generateAWSFolderPath(sessionId: sessionId, additionalData: lastFile), date: Date())
                self?.awsS3UploadManager.sendCollectedDataToS3()
            }).store(in: &cancellable)

        navigation.vpsPosition.recordingOutputPublisher
            .compactMap { $0 }
            .sink { [weak self] (identifier, data, sessionId, lastFile) in
              guard let storeId = self?.activeStore?.id else { return }
              let sessionId = self?.analytics.visitId?.description ?? sessionId
              let folderPath = self?.generateAWSFolderPathForMagData(storeId: storeId.description, sessionId: sessionId)
              self?.awsS3UploadManager.prepareDataToSend(identifier: identifier, data: data, folderPath: folderPath, date: .init())
            }.store(in: &cancellable)

        navigation.vpsPosition.outputSignalPublisher
            .compactMap { $0 }
            .sink { [weak self] (signal) in
              guard let self = self else { return }
              switch signal {
              case .position(position: let position):
                setVPSPosition.invoke(vpsPosition: position)
                floorManager.onNewPostion(location: position.point)
                mapManager?.set(currentLocation: position)
                mapController?.updateUserLocation(position: position)
                analytics.onNewPositionBundle(position: position)
              case .latLng(let latLng):
                mapController?.updateLatLngPosition(latLng: latLng)
                analytics.geopositionsManager.update(location: latLng)
                setGPSPosition.invoke(gpsPosition: latLng.gpsLocation)
              case .gps(let location):
                mapController?.update(location: location)
                setGPSPosition.invoke(gpsPosition: location)
              case .ux(position: let position): break
                //mapController?.updateUserLocation(newLocation: position.position, std: position.std)
              case .ml(position: let position):
                if let converter = realConverter {
                  let coordinate = position.point.convertFromMeterToLatLng(converter: converter)
                  mapController?.updateMLPosition(coordinate: coordinate)
                  analytics.addMLPositions(coordinate: coordinate, date: position.timestamp)
                } else {
                  mapController?.updateMLPosition(point: position.point)
                }
                analytics.addMLPositions(position: position)
              case .particles(positions: let positions):
                mapController?.updateParticlePositions(positions: positions)
              case .rotation(heading: let heading):
                let heading = (vpsToMapboxAngle(angle: heading + offset)).remainder(dividingBy: 360.0)
                mapController?.updateUserDirection(newDirection: heading)
              case .rescueMode: analytics.rescueMode()
              case .floorChange(difference: let difference, timestamp: let timestamp):
                floorManager.onNewFloor(floor: difference)
              case .consistencyScoreSignal(let score):
                analytics.report(visitScore: score)
                mapController?.visitScore(score)
              case .userInfoVPSError(let error):
                createCrashReport(error: error)
                navigation.stop()
                mapController?.stop()
              }
            }.store(in: &cancellable)
        
        navigation.accuracyPublisher
            .compactMap { $0 }
            .sink { [weak self] (data) in
                self?.analytics.accuracyUploader?.upload(syncEvent: data.event, isFloorSwap: data.isFloorSwap)
            }.store(in: &cancellable)

        navigation.scanEventsPublisher
          .compactMap { $0 }
          .sink { [weak self] (events) in
            events.forEach { self?.analytics.postScanEvents(scanEvent: $0) }
          }.store(in: &cancellable)

        recording.sendDataPublisher
            .sink { [weak self] (_) in
                self?.awsS3UploadManager.sendCollectedDataToS3(objects: self?.awsS3UploadManager.getAllRecordedObjects ?? [])
            }.store(in: &cancellable)

        analytics.zoneManager.onEnterPublisher
            .compactMap { $0 }
            .sink { [weak self] (zone) in
                self?.mapController?.zone.onEnterPublisher.send(zone)
            }.store(in: &cancellable)

        analytics.zoneManager.onExitPublisher
            .compactMap { $0 }
            .sink { [weak self] (zone) in
                self?.mapController?.zone.onExitPublisher.send(zone)
            }.store(in: &cancellable)
    }

    func generateAWSFolderPath(sessionId: String, additionalData: Bool = false) -> String {
        let serverAddress = config.connection.tt2CentralServer.baseUrl.trimServerAddress
        let dataServerAddress = (config.connection.tt2DataServer?.baseUrl ?? activeStore?.statServerConnection.serverAddress ?? "undefined").trimServerAddress
        let folderPath: String = "\(serverAddress)/\(dataServerAddress)/\(sessionId)/"
        if additionalData, let tags = createTT2Tags(serverAddress: serverAddress, dataServerAddress: dataServerAddress, sessionId: sessionId) {
            awsS3UploadManager.prepareDataToSend(identifier: "tags.json", data: tags, folderPath: folderPath, date: Date())
        }
        return folderPath
    }

    func createTT2Tags(serverAddress: String, dataServerAddress: String, sessionId: String) -> String? {
        struct TT2Tags: Codable {
          let tags: [String:String]
        }
        analytics.tt2Tags["tt2CentralServerURL"] = serverAddress
        analytics.tt2Tags["tt2DataServerURL"] = dataServerAddress
        analytics.tt2Tags["tt2RtlsOptionsId"] = try? floorManager.activeFloor.id.description
        analytics.tt2Tags["tt2StoreId"] = activeStore?.id.description
        analytics.tt2Tags["tt2VisitId"] = sessionId
        analytics.tt2Tags["tt2ClientId"] = activeClient?.clientId.description
        let tags = TT2Tags(tags: analytics.tt2Tags)
        guard let data = try? JSONEncoder().encode(tags) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func generateAWSFolderPathForMagData(storeId: String, sessionId: String) -> String {
      let serverAddress = config.connection.tt2CentralServer.baseUrl.trimServerAddress
      return "mag-mapping/\(serverAddress)/\(storeId)/\(sessionId)/"
    }

    func createCrashReport(error: VPSOutputSignal.UserInfoVPSError) {
      let date = Date()
      let report = TT2CrashReport(
        systemTimestamp: date.currentTimeMillis.description,
        os: UIDevice.current.systemName,
        deviceModel: UIDevice.current.modelName,
        sdkVersion: TT2.version,
        vpsVersion: vpsVersion,
        centralServerAddress: config.connection.tt2CentralServer.baseUrl.trimServerAddress,
        stackTrace: error.stacktrace
      )

      do {
        let data = try JSONEncoder().encode(report)
        guard let stringData = String(data: data, encoding: .utf8) else { return }
        let identifier: String
        let folderPath: String
        if let id =  analytics.visitId {
          identifier = "crashReport.json"
          folderPath = generateAWSFolderPath(sessionId: id.description)
        } else {
          let storeId = activeStore?.id.description ?? "undefined"
          let formatter = DateFormatter()
          formatter.dateFormat = "yyyyMMdd-HHmmss"
          identifier = "\(formatter.string(from: date))-\(UUID().uuidString.uppercased())-crashReport.json"
          folderPath = generateFolderPathForRogueCrashReport(storeId: storeId)
        }
        awsS3UploadManager.prepareDataToSend(
          identifier: identifier,
          data: stringData,
          folderPath: folderPath,
          date: date
        )
        awsS3UploadManager.sendCollectedDataToS3()
      } catch {
        Logger(verbosity: .error).log(tag: tag, message: "Trouble encoding crash report: \(error)")
      }
    }

    func generateFolderPathForRogueCrashReport(storeId: String) -> String {
      let serverAddress = config.connection.tt2CentralServer.baseUrl.trimServerAddress
      return "rouge-crash-reports/\(serverAddress)/\(storeId)/\(UIDevice.current.systemName)"
    }

    private func vpsToMapboxAngle(angle: Double) -> Double {
        90.0 - angle
    }

    func initRealWorldConverter() {
      guard
        let map = mapController,
        let coordinate = map.currentGPSCoordinate
      else { return }
      initRealWorldConverter(coordinate: coordinate)
    }

    func initRealWorldConverter(point: CGPoint) {
      guard let map = mapController else { return }
      initRealWorldConverter(coordinate: map.getCoordinate(point: point))
    }

    private var realConverter: ICoordinateConverterReal?
    func initRealWorldConverter(coordinate: CLLocationCoordinate2D) {
      realConverter = RealCoordinateConverter(
        latLngOrigin: coordinate,
        mapAngleInDegrees: 0.0,
        earthRadiusInMeters: 6378137.0,
        pixelsPerMeter: 50
      )
    }
}

private extension String {
  var trimServerAddress: String {
    var modified = self
    if hasPrefix("http://") { modified.removeFirst(7) }
    if hasPrefix("https://") { modified.removeFirst(8) }
    if hasSuffix("/api/v1") || hasSuffix("/api/v2") { modified.removeLast(7) }
    return modified.components(separatedBy: "/").first ?? modified
  }
}

struct TT2CrashReport: Codable {
  var systemTimestamp: String
  var os: String
  var deviceModel: String
  var sdkVersion: String
  var vpsVersion: String
  var centralServerAddress: String
  var stackTrace: String?
}
