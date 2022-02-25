//
// MapZoneParser
// VSTT2
//
// Created by Hripsime on 2021-12-20
// Copyright Virtual Stores - 2021

import Foundation
import CoreGraphics
import VSFoundation

private typealias PolygonJson = Dictionary<String, AnyObject>

public class MapZoneParser: NSObject {
    public static func getMapZonesData(fromJsonData data: Data) -> (mapzones: [MapZone], mapPoints: [MapZonePoint]) {
        let json = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! PolygonJson
        var mapZones: [MapZone] = []
        var mapZonePoints: [MapZonePoint] = []
        let store = Array(json)[0].value as! NSDictionary
        let data = store["data"] as! NSDictionary
        let features = data["features"] as! [AnyObject]
        for feature in features {
            if feature != nil {
                let properties = feature["properties"] as! NSDictionary
                if let id = feature["id"] as? String {
                    let geometry = feature["geometry"] as! NSDictionary
                    guard let type = geometry["type"] as? String else { continue }
                    switch type {
                    case "Polygon":
                        let cordinates = geometry["coordinates"] as! [[[Double]]]
                        let points: [CGPoint] = cordinates[0].map { (coords) -> CGPoint in
                            return CGPoint(x: coords[0], y: coords[1])
                        }
                        let name = properties["name"] ?? ""
                        let parentId = properties["parentId"] as? String
                        let description = properties["description"] as? String
                        mapZones.append(MapZone(id: id, name: name as! String, zone: points, parentId: parentId, description: description))
                    case "Point":
                        let description = properties["description"] as! String
                        let geometry = feature["geometry"] as! NSDictionary
                        let coordinates = geometry["coordinates"] as! [Double]
                        let parentId = properties["parentId"] as? String
                        
                        mapZonePoints.append(MapZonePoint(name: description, point: CGPoint(x: coordinates[0], y: coordinates[1]), parentId: parentId))
                    default: continue
                    }
                }
            }
        }
        return (mapZones, mapZonePoints)
    }
    
    enum MapZoneParserError: Error {
        case parsingFailed
    }
    
    public static func getMapZonesDataTest(fromJsonData data: Data) -> [MapZone] {
        var output: [MapZone] = []
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? PolygonJson,
                  let store = Array(json)[0].value as? NSDictionary,
                  let data = store["data"] as? NSDictionary,
                  let features = data["features"] as? [AnyObject]
            else {
                throw MapZoneParserError.parsingFailed
            }
            
            for feature in features {
                guard let properties = feature["properties"] as? NSDictionary,
                      let id = properties["id"] as? Int,
                      let geometry = feature["geometry"] as? NSDictionary,
                      let coordinates = geometry["coordinates"] as? [[[Double]]]
                else {
                    throw MapZoneParserError.parsingFailed
                }
                
                let points: [CGPoint] = coordinates[0].map { (coords) -> CGPoint in
                    return CGPoint(x: coords[0], y: coords[1])
                }
                
                let name = properties["name"] as? String ?? ""
                let parentId = properties["parentId"] as? String
                let description = properties["description"] as? String
                output.append(MapZone(id: String(id), name: name, zone: points, parentId: parentId, description: description))
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return output
    }
}

