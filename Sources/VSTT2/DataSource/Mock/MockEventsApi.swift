//
//  EventsApi.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-04-30.
//

class MockEventsApi {}

extension MockEventsApi: IEventsApi {
  func get(storeId: Int64, completion: @escaping (Result<[TriggerEventDto], Error>) -> ()) {
    completion(.success([]))
  }
}
