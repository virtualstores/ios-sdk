//
//  EventsApi.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-04-30.
//

import Combine

protocol IEventsApi {
  func get(storeId: Int64, completion: @escaping (Result<[TriggerEventDto], Error>) -> ())
}

class EventsApi {
  let service = TriggerEventsService(with: NetworkManager())
  private var cancellables = Set<AnyCancellable>()
}

extension EventsApi: IEventsApi {
  func get(storeId: Int64, completion: @escaping (Result<[TriggerEventDto], Error>) -> ()) {
    service
      .call(with: .init(storeId: storeId))
      .sink { (result) in
        switch result {
        case .finished: break
        case .failure(let error):
          completion(.failure(error))
        }
      } receiveValue: { (dto) in
        completion(.success(dto))
      }.store(in: &cancellables)
  }
}
