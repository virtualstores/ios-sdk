//
//  EventsUseCases.swift
//
//
//  Created by Théodore Roos on 2024-05-17.
//

import Foundation
import VSFoundation

class DecideWhichTriggerEventToDisplayUseCase {
  @Inject var repository: IUserRepository

  func invoke(triggerEvents: [TriggerEvent]) -> TriggerEvent? {
    triggerEvents
      .filterImageEvents()
      .filterProfileTags(profile: repository.getUserProfile())
      .normalizeShareOfVoice()
      .filterSingleShareOfVoice()
  }
}

private extension Array where Element == TriggerEvent {
  func filterImageEvents() -> [TriggerEvent] {
    filter({ $0.tags[TriggerEvent.DefaultTags.displayType] == TriggerEvent.DefaultTags.DisplayTypeEnum.image.rawValue })
  }
  
  func filterProfileTags(profile: TT2UserProfile?) -> [TriggerEvent] {
    filter { (event) in
      var result = true
      profile?.tags.forEach { (key, value) in
        guard 
          let tag = event.tags[key], 
          let data = tag.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String]
        else { return }
        if !json.contains(value) {
          result = false
        }
      }
      return result
    }
  }

  func normalizeShareOfVoice() -> [(event: TriggerEvent, range: Range<Double>)] {
    var index = 0.0
    var result = [(event: TriggerEvent, range: Range<Double>)]()
    let totalSoV = checkTotalShareOfVoice()
    if totalSoV  <= 1.0 {
      forEach {
        let shareOfVoice = $0.shareOfVoice()
        let from = index
        let to = index + shareOfVoice
        result.append(($0, Range(uncheckedBounds: (from, to))))
        index = to
      }
    } else {
      forEach {
        let newSoV = $0.shareOfVoice() / totalSoV
        $0.add(tags: [TriggerEvent.DefaultTags.shareOfVoice: String(newSoV)])
      }
      forEach {
        let shareOfVoice = $0.shareOfVoice()
        let from = index
        let to = index + shareOfVoice
        result.append(($0, Range(uncheckedBounds: (from, to))))
        index = to
      }
    }
    return result
  }

  func checkTotalShareOfVoice() -> Double {
    map { $0.shareOfVoice() }.reduce(0, +)
  }
}

private extension Array where Element == (event: TriggerEvent, range: Range<Double>) {
  func filterSingleShareOfVoice() -> TriggerEvent? {
    let random = Double.random(in: 0...1)
    return first(where: { $0.range.contains(random) })?.event
  }
}
