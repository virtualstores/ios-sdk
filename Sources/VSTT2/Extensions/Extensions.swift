//
//  Extensions.swift
//  VSTT2
//
//  Created by Théodore Roos on 2025-09-25.
//

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
