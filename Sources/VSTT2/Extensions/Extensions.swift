//
//  Extensions.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-09-25.
//

import Combine
import Foundation

extension Comparable {
  /// Returns this value clamped to the given closed range.
  ///
  /// - Parameter limits: The closed range within which to clamp this value.
  /// - Returns: The value itself if it lies within `limits`,
  ///            otherwise the nearest bound of `limits`.
  ///
  /// Example:
  /// ```
  /// 15.clamped(to: 0...10) // 10
  /// 5.clamped(to: 0...10)  // 5
  /// ```
  func clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }

  /// Returns this value coerced into the inclusive range between the given minimum and maximum.
  ///
  /// Equivalent to Kotlin’s `coerceIn(min, max)`.
  ///
  /// - Parameters:
  ///   - minValue: The minimum allowed value.
  ///   - maxValue: The maximum allowed value.
  /// - Returns: The value itself if it lies in `[minValue, maxValue]`,
  ///            otherwise the nearest bound.
  ///
  /// Example:
  /// ```
  /// 15.coerceIn(0, 10)  // 10
  /// -3.coerceIn(0, 10)  // 0
  /// 5.coerceIn(0, 10)   // 5
  /// ```
  func coerceIn(_ minValue: Self, _ maxValue: Self) -> Self {
    self.clamped(to: minValue...maxValue)
  }

  /// Returns this value if it is greater than or equal to `minValue`,
  /// otherwise returns `minValue`.
  ///
  /// Equivalent to Kotlin’s `coerceAtLeast(min)`.
  func coerceAtLeast(_ minValue: Self) -> Self {
    max(self, minValue)
  }

  /// Returns this value if it is less than or equal to `maxValue`,
  /// otherwise returns `maxValue`.
  ///
  /// Equivalent to Kotlin’s `coerceAtMost(max)`.
  func coerceAtMost(_ maxValue: Self) -> Self {
    min(self, maxValue)
  }
}

extension Array where Element: Equatable {
  mutating func removeFirst(of element: Element) {
    guard let index = firstIndex(of: element) else { return }
    remove(at: index)
  }
}

extension Double {
  var asAnalyticsDuration: String {
    guard self >= 0 else { return "00:00:00" }
    let days = Int(self) / 86400
    let hours = (Int(self) / 3600 % 24).formatNumber(decimals: 2)
    let minutes = (Int(self) / 60 % 60).formatNumber(decimals: 2)
    let seconds = (Int(self) % 60).formatNumber(decimals: 2)
    let microseconds = Int(self.truncatingRemainder(dividingBy: 1) * 1000).formatNumber(decimals: 3)

    return "\(days).\(hours):\(minutes):\(seconds).\(microseconds)"
  }
}

extension Int {
  func formatNumber(decimals: Int) -> String {
    String(format: "%0\(decimals)d", self)
  }
}

extension String {
  static func dateWithStandardFormatter(_ date: Date) -> String {
    DateFormatter.standardFormatter.string(from: date)
  }
}

extension URL {
  init?(string url: String?) {
    guard let urlString = url, let url = URL(string: urlString) else {
      return nil
    }
    self = url
  }
}

extension Publisher {
  static func justOrFail<Output>(_ work: () throws -> Output) -> AnyPublisher<Output, Error> {
    do {
      return Just(try work())
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    } catch {
      return .fail(with: error)
    }
  }

  static func fail<T>(with error: Error) -> AnyPublisher<T, Error> {
    Fail(error: error).eraseToAnyPublisher()
  }

  func asResult() -> AnyPublisher<Result<Output, Error>, Never> {
    map { .success($0) }
      .catch { Just(.failure($0)) }
      .eraseToAnyPublisher()
  }

  func asFailure() -> AnyPublisher<Error?, Never> {
    map { (_) in .none }
      .catch { Just($0) }
      .eraseToAnyPublisher()
  }

  func ensure(_ condition: @escaping (Output) -> Bool, elseThrow error: @autoclosure @escaping () -> Error) -> AnyPublisher<Output, Error> {
    tryMap {
      guard condition($0) else { throw error() }
      return $0
    }
    .eraseToAnyPublisher()
  }
}
