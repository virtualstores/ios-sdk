//
// Formatters
// VSTT2
//
// Created by Hripsime on 2021-12-21.
// Copyright Virtual Stores - 2021

import Foundation

public extension DateFormatter {
    static let standardFormatter = DateFormatter(timeZone: TimeZone(secondsFromGMT: 0), dateFormat: "yyyy-MM-dd'T'HH:mm:ss'Z'")

    convenience init(timeZone: TimeZone?, dateFormat: String? = nil) {
        self.init()

        self.timeZone = timeZone

        if let dateFormat = dateFormat {
            self.dateFormat = dateFormat
        }
    }
}
