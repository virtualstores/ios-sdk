//
// Mapfence
// VSTT2
//
// Created by Hripsime on 2021-12-21
// Copyright Virtual Stores - 2021

struct Mapfence: Codable {
    let type: String
    let properties: Properties
    let coordinates: [[[[Double]]]]
}

struct Properties: Codable {
    let width, height: Double
}
