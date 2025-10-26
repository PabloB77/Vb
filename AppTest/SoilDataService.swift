//
//  SoilDataService.swift
//  AppTest
//
//  Created by Pablo Badra on 10/6/25.
//

import Foundation
import CoreLocation

struct SoilDataService {
    private let baseURL = "https://sdmdataaccess.sc.egov.usda.gov"
    
    // MARK: - Data Models
    struct MapUnit: Identifiable {
        let id = UUID()
        let mukey: String
        let muname: String
        let musym: String
        let compname: String
        let comppct_r: Double
        let taxclname: String
        let mapunit_acres_in_aoi: Double
        let mapunit_pct_of_aoi: Double
        let component_pct_of_aoi: Double
        
        // Add these with default values since they're not in the original model
        var irrcapcl: String? { return nil }
        var drainagecl: String? { return nil }
        var slopegradwta: String? { return nil }
        var flodfreqcl: String? { return nil }
        var erocl: String? { return nil }
        var runoff: String? { return nil }
    }
    
    struct Component {
        let cokey: String
        let compname: String
        let comppct_r: Double
        let slope_r: Double
        let drainage: String
    }
    
    struct SoilProperty {
        let property: String
        let value: String
        let unit: String
    }
    
    // MARK: - Public Functions
    
    /// Get soil composition for a square area defined by coordinates
    func getSoilComposition(
        centerLatitude: Double,
        centerLongitude: Double,
        sideLengthMeters: Double = 1000,
        completion: @escaping (Result<[MapUnit], Error>) -> Void
    ) {
        // Convert center point to bounding box
        let boundingBox = createBoundingBox(
            centerLatitude: centerLatitude,
            centerLongitude: centerLongitude,
            sideLengthMeters: sideLengthMeters
        )
        
        // First get map units in the area
        getMapUnitsInArea(boundingBox: boundingBox) { result in
            switch result {
            case .success(let mapUnits):
                completion(.success(mapUnits))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get detailed soil properties for a specific map unit
    func getSoilProperties(
        mukey: String,
        completion: @escaping (Result<[SoilProperty], Error>) -> Void
    ) {
        let query = """
        SELECT 
            prop.propname as property,
            prop.propdesc as description,
            prop.propunit as unit,
            prop.propabbrev as abbreviation
        FROM component c
        INNER JOIN chtexturegrp ctg ON c.cokey = ctg.cokey
        INNER JOIN chtexture ct ON ctg.chtgkey = ct.chtgkey
        INNER JOIN texture tx ON ct.texkey = tx.texkey
        INNER JOIN prop ON tx.texkey = prop.texkey
        WHERE c.mukey = '\(mukey)'
        """
        
        executeTabularQuery(query: query) { result in
            switch result {
            case .success(let data):
                let properties = self.parseSoilProperties(from: data)
                completion(.success(properties))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get soil components for a specific map unit
    func getSoilComponents(
        mukey: String,
        completion: @escaping (Result<[Component], Error>) -> Void
    ) {
        let query = """
        SELECT 
            c.cokey,
            c.compname,
            c.comppct_r,
            c.slope_r,
            c.drainagecl
        FROM component c
        WHERE c.mukey = '\(mukey)'
        """
        
        executeTabularQuery(query: query) { result in
            switch result {
            case .success(let data):
                let components = self.parseComponents(from: data)
                completion(.success(components))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Functions
    
    private func createBoundingBox(
        centerLatitude: Double,
        centerLongitude: Double,
        sideLengthMeters: Double
    ) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        // Convert meters to degrees (approximate)
        let latDelta = sideLengthMeters / 111000.0 // 1 degree ≈ 111km
        let lonDelta = sideLengthMeters / (111000.0 * cos(centerLatitude * .pi / 180.0))
        
        return (
            minLat: centerLatitude - latDelta / 2,
            maxLat: centerLatitude + latDelta / 2,
            minLon: centerLongitude - lonDelta / 2,
            maxLon: centerLongitude + lonDelta / 2
        )
    }
    
    private func getMapUnitsInArea (
        boundingBox: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double),
        completion: @escaping (Result<[MapUnit], Error>) -> Void
    ) {
        // Build WKT polygon in lon lat order (WGS84)
        let wkt = "POLYGON((\(boundingBox.minLon) \(boundingBox.minLat), \(boundingBox.maxLon) \(boundingBox.minLat), \(boundingBox.maxLon) \(boundingBox.maxLat), \(boundingBox.minLon) \(boundingBox.maxLat), \(boundingBox.minLon) \(boundingBox.minLat)))"
        
        let query = """
        ~DeclareGeometry(@aoi)~
        select @aoi = geometry::STPolyFromText('\(wkt)', 4326);

        ~DeclareIdGeomTable(@intersectedPolygonGeometries)~
        ~GetClippedMapunits(@aoi,polygon,geo,@intersectedPolygonGeometries)~

        ~DeclareIdGeogTable(@intersectedPolygonGeographies)~
        ~GetGeogFromGeomWgs84(@intersectedPolygonGeometries,@intersectedPolygonGeographies)~

        SELECT 
            M.mukey,
            M.musym,
            M.muname,
            C.compname,
            C.comppct_r as component_pct_of_mapunit,
            C.taxclname,
            ROUND(SUM(geog.STArea()) * 0.000247105, 2) as mapunit_acres_in_aoi,
            ROUND(100.0 * SUM(geog.STArea()) / (SELECT SUM(geog.STArea()) FROM @intersectedPolygonGeographies), 1) as mapunit_pct_of_aoi,
            ROUND((C.comppct_r / 100.0) * 100.0 * SUM(geog.STArea()) / (SELECT SUM(geog.STArea()) FROM @intersectedPolygonGeographies), 1) as component_pct_of_aoi
        FROM @intersectedPolygonGeographies P
        INNER JOIN mapunit M ON P.id = M.mukey
        LEFT JOIN component C ON M.mukey = C.mukey
        GROUP BY M.mukey, M.musym, M.muname, C.compname, C.comppct_r, C.taxclname
        ORDER BY mapunit_pct_of_aoi DESC, component_pct_of_mapunit DESC
        """
        
        executeTabularQuery(query: query) { result in
            switch result {
            case .success(let data):
                let mapUnits = self.parseMapUnits(from: data)
                completion(.success(mapUnits))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func executeTabularQuery(
        query: String,
        completion: @escaping (Result<[[String: Any]], Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/tabular/post.rest") else {
            completion(.failure(SoilDataError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Build JSON body
        let requestBody: [String: String] = [
            "query": query,
            "format": "json+columnname"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        let session = URLSession(configuration: config)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                completion(.failure(SoilDataError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(SoilDataError.noData))
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(.failure(SoilDataError.parsingError))
                    return
                }
                
                // The API returns data in a "Table" array
                guard let table = json["Table"] as? [[Any]] else {
                    completion(.success([]))
                    return
                }
                
                // First row contains column names
                guard table.count > 1 else {
                    completion(.success([]))
                    return
                }
                
                let columnNames = table[0] as? [String] ?? []
                var results: [[String: Any]] = []
                
                // Parse data rows
                for i in 1..<table.count {
                    let row = table[i]
                    var rowDict: [String: Any] = [:]
                    
                    for (index, columnName) in columnNames.enumerated() {
                        if index < row.count {
                            rowDict[columnName] = row[index]
                        }
                    }
                    results.append(rowDict)
                }
                
                completion(.success(results))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func parseMapUnits(from data: [[String: Any]]) -> [MapUnit] {
        return data.compactMap { row in
            // Handle different possible data types
            let mukey: String
            if let key = row["mukey"] as? String {
                mukey = key
            } else if let key = row["mukey"] as? Int {
                mukey = String(key)
            } else if let key = row["mukey"] as? NSNumber {
                mukey = key.stringValue
            } else {
                return nil
            }
            
            guard let muname = row["muname"] as? String,
                  let musym = row["musym"] as? String else {
                return nil
            }
            
            // Handle muacres as various types
            let muacres: Double
            if let acres = row["muacres"] as? Double {
                muacres = acres
            } else if let acres = row["muacres"] as? Int {
                muacres = Double(acres)
            } else if let acres = row["muacres"] as? String, let value = Double(acres) {
                muacres = value
            } else if let acres = row["muacres"] as? NSNumber {
                muacres = acres.doubleValue
            } else {
                muacres = 0.0
            }
            
            // Handle component data
            let compname = row["compname"] as? String ?? "Unknown"
            let taxclname = row["taxclname"] as? String ?? "Unknown"
            
            let comppct_r: Double
            if let pct = row["component_pct_of_mapunit"] as? Double {
                comppct_r = pct
            } else if let pct = row["component_pct_of_mapunit"] as? Int {
                comppct_r = Double(pct)
            } else if let pct = row["component_pct_of_mapunit"] as? String, let value = Double(pct) {
                comppct_r = value
            } else if let pct = row["component_pct_of_mapunit"] as? NSNumber {
                comppct_r = pct.doubleValue
            } else {
                comppct_r = 0.0
            }
            
            let mapunit_acres_in_aoi: Double
            if let acres = row["mapunit_acres_in_aoi"] as? Double {
                mapunit_acres_in_aoi = acres
            } else if let acres = row["mapunit_acres_in_aoi"] as? Int {
                mapunit_acres_in_aoi = Double(acres)
            } else if let acres = row["mapunit_acres_in_aoi"] as? String, let value = Double(acres) {
                mapunit_acres_in_aoi = value
            } else if let acres = row["mapunit_acres_in_aoi"] as? NSNumber {
                mapunit_acres_in_aoi = acres.doubleValue
            } else {
                mapunit_acres_in_aoi = 0.0
            }
            
            let mapunit_pct_of_aoi: Double
            if let pct = row["mapunit_pct_of_aoi"] as? Double {
                mapunit_pct_of_aoi = pct
            } else if let pct = row["mapunit_pct_of_aoi"] as? Int {
                mapunit_pct_of_aoi = Double(pct)
            } else if let pct = row["mapunit_pct_of_aoi"] as? String, let value = Double(pct) {
                mapunit_pct_of_aoi = value
            } else if let pct = row["mapunit_pct_of_aoi"] as? NSNumber {
                mapunit_pct_of_aoi = pct.doubleValue
            } else {
                mapunit_pct_of_aoi = 0.0
            }
            
            let component_pct_of_aoi: Double
            if let pct = row["component_pct_of_aoi"] as? Double {
                component_pct_of_aoi = pct
            } else if let pct = row["component_pct_of_aoi"] as? Int {
                component_pct_of_aoi = Double(pct)
            } else if let pct = row["component_pct_of_aoi"] as? String, let value = Double(pct) {
                component_pct_of_aoi = value
            } else if let pct = row["component_pct_of_aoi"] as? NSNumber {
                component_pct_of_aoi = pct.doubleValue
            } else {
                component_pct_of_aoi = 0.0
            }
            
            return MapUnit(mukey: mukey, muname: muname, musym: musym, compname: compname, comppct_r: comppct_r, taxclname: taxclname, mapunit_acres_in_aoi: mapunit_acres_in_aoi, mapunit_pct_of_aoi: mapunit_pct_of_aoi, component_pct_of_aoi: component_pct_of_aoi)
        }
    }
    
    private func parseComponents(from data: [[String: Any]]) -> [Component] {
        return data.compactMap { row in
            guard let cokey = row["cokey"] as? String,
                  let compname = row["compname"] as? String,
                  let comppct_r = row["comppct_r"] as? Double,
                  let slope_r = row["slope_r"] as? Double,
                  let drainage = row["drainagecl"] as? String else {
                return nil
            }
            return Component(cokey: cokey, compname: compname, comppct_r: comppct_r, slope_r: slope_r, drainage: drainage)
        }
    }
    
    private func parseSoilProperties(from data: [[String: Any]]) -> [SoilProperty] {
        return data.compactMap { row in
            guard let property = row["property"] as? String,
                  let value = row["description"] as? String,
                  let unit = row["unit"] as? String else {
                return nil
            }
            return SoilProperty(property: property, value: value, unit: unit)
        }
    }
}

// MARK: - Error Types
enum SoilDataError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case parsingError
}
