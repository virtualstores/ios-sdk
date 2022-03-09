//
// RecordedPosition
// VSTT2
//
// Created by Hripsime on 2022-01-13.
// Copyright Virtual Stores - 2021

import Foundation

struct RecordedPosition: Codable {
    let xPosition: Double
    let yPosition: Double
    let timeStamp: String
    
    private enum CodingKeys: String, CodingKey {
        case xPosition = "x"
        case yPosition = "y"
        case timeStamp = "timeStamp"
    }
}
