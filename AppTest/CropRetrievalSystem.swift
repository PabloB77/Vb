import Foundation

struct Crop: Codable {
    let commodityType: String
    let genus: String
    let revenuePerAcre: String
    let usdaZones: String
    let preferredSoilDrainage: String
    let preferredPH: String
    let soilType: String
}

class CropRetrievalSystem {
    private var crops: [Crop] = []
    
    func loadCrops(from filename: String) throws {
        let fileManager = FileManager.default
        
        // Try to load from app bundle first
        if let bundlePath = Bundle.main.path(forResource: filename, ofType: "csv") {
            print("📁 Loading CSV file from bundle: \(bundlePath)")
            let csvData = try String(contentsOfFile: bundlePath, encoding: .utf8)
            try parseCropData(csvData)
            return
        }
        
        // Fallback to Documents directory
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let csvPath = documentsDirectory.appendingPathComponent("\(filename).csv")
        
        print("📁 Looking for CSV file at: \(csvPath.path)")
        
        guard fileManager.fileExists(atPath: csvPath.path) else {
            throw NSError(domain: "FileNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Crops.csv file not found at \(csvPath.path)"])
        }
        
        let csvData = try String(contentsOf: csvPath, encoding: .utf8)
        try parseCropData(csvData)
    }
    
    private func parseCropData(_ csvData: String) throws {
        let lines = csvData.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw NSError(domain: "InvalidFile", code: 400, userInfo: [NSLocalizedDescriptionKey: "CSV file is empty or no data rows"])
        }
        
        var parsedCrops: [Crop] = []
        let headers = parseCSVLine(lines[0])
        print("📋 CSV Headers: \(headers)")
        
        for (index, line) in lines.dropFirst().enumerated() {
            let values = parseCSVLine(line)
            
            if values.count < 7 {
                print("⚠️ Skipping line \(index + 2): insufficient columns (\(values.count))")
                continue
            }
            
            let crop = Crop(
                commodityType: values[0],
                genus: values[1],
                revenuePerAcre: values[2],
                usdaZones: values[3],
                preferredSoilDrainage: values[4],
                preferredPH: values[5],
                soilType: values[6]
            )
            
            parsedCrops.append(crop)
        }
        
        self.crops = parsedCrops
        print("✅ Loaded \(parsedCrops.count) crops from CSV")
        
        if !parsedCrops.isEmpty {
            print("\n🔍 Sample of loaded crops:")
            for crop in parsedCrops.prefix(3) {
                print("   - \(crop.commodityType): pH=\(crop.preferredPH), Zones=\(crop.usdaZones), Soil=\(crop.soilType), Drainage=\(crop.preferredSoilDrainage)")
            }
        }
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for character in line {
            switch character {
            case "\"":
                inQuotes.toggle()
            case ",":
                if inQuotes {
                    currentField.append(character)
                } else {
                    result.append(currentField.trimmingCharacters(in: .whitespaces))
                    currentField = ""
                }
            default:
                currentField.append(character)
            }
        }
        
        result.append(currentField.trimmingCharacters(in: .whitespaces))
        return result
    }
    
    func findBestCrops(soilType: String, pH: Double, drainage: String, usdaZone: String, limit: Int = 20) -> [Crop] {
        print("\n🔍 Searching for crops matching:")
        print("   Soil Type: \(soilType)")
        print("   pH: \(pH)")
        print("   Drainage: \(drainage)")
        print("   USDA Zone: \(usdaZone)")
        
        guard !crops.isEmpty else {
            print("❌ No crops loaded to search!")
            return []
        }
        
        let scoredCrops = crops.map { crop -> (Crop, Double, Double) in
            let matchScore = calculateFuzzyMatchScore(crop: crop,
                                               soilType: soilType,
                                               pH: pH,
                                               drainage: drainage,
                                               usdaZone: usdaZone)
            let revenueScore = calculateRevenueScore(crop.revenuePerAcre)
            return (crop, matchScore, revenueScore)
        }
        
        let matchedCrops = scoredCrops.sorted {
            if $0.1 == $1.1 {
                return $0.2 > $1.2
            }
            return $0.1 > $1.1
        }
        
        print("\n📊 Scoring breakdown for top matches:")
        print("=" + String(repeating: "=", count: 59))
        
        for (index, (crop, matchScore, revenueScore)) in matchedCrops.prefix(limit).enumerated() {
            let (phScore, zoneScore, soilScore, drainageScore) = getDetailedScores(crop: crop,
                                                                                  soilType: soilType,
                                                                                  pH: pH,
                                                                                  drainage: drainage,
                                                                                  usdaZone: usdaZone)
            print("\(index + 1). \(crop.commodityType)")
            print("   Total Score: \(String(format: "%.2f", matchScore))")
            print("   Revenue Score: \(String(format: "%.2f", revenueScore))")
            print("   pH: \(String(format: "%.2f", phScore)) (\(crop.preferredPH))")
            print("   Zone: \(String(format: "%.2f", zoneScore)) (\(crop.usdaZones))")
            print("   Soil: \(String(format: "%.2f", soilScore)) (\(crop.soilType))")
            print("   Drainage: \(String(format: "%.2f", drainageScore)) (\(crop.preferredSoilDrainage))")
            print("   Revenue: \(crop.revenuePerAcre)")
            print("   " + String(repeating: "-", count: 40))
        }
        
        return Array(matchedCrops.prefix(limit).map { $0.0 })
    }
    
    private func calculateFuzzyMatchScore(crop: Crop, soilType: String, pH: Double, drainage: String, usdaZone: String) -> Double {
        let phScore = calculatePHDistance(crop.preferredPH, targetPH: pH)
        let zoneScore = calculateZoneDistance(crop.usdaZones, targetZone: usdaZone)
        let soilScore = calculateSoilSimilarity(crop.soilType, targetSoil: soilType)
        let drainageScore = calculateDrainageSimilarity(crop.preferredSoilDrainage, targetDrainage: drainage)
        let revenueScore = calculateRevenueScore(crop.revenuePerAcre)
        
        // Weighted score with revenue as a tiebreaker/booster
        let weightedScore = (phScore * 0.35) + (zoneScore * 0.25) + (soilScore * 0.20) + (drainageScore * 0.10) + (revenueScore * 0.10)
        
        return weightedScore
    }
    
    private func calculateRevenueScore(_ revenueString: String) -> Double {
        let cleaned = revenueString
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        let numberPattern = "\\d+"
        let regex = try? NSRegularExpression(pattern: numberPattern)
        let matches = regex?.matches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned))
        
        guard let matches = matches, matches.count >= 2 else {
            return 0.5
        }
        
        let numbers = matches.compactMap { match -> Double? in
            let range = Range(match.range, in: cleaned)!
            return Double(String(cleaned[range]))
        }
        
        let maxRevenue = numbers.max() ?? 0
        let minRevenue = numbers.min() ?? 0
        let averageRevenue = (maxRevenue + minRevenue) / 2
        
        let normalizedScore = min(averageRevenue / 50000.0, 1.0)
        
        return normalizedScore
    }
    
    private func getDetailedScores(crop: Crop, soilType: String, pH: Double, drainage: String, usdaZone: String) -> (Double, Double, Double, Double) {
        let phScore = calculatePHDistance(crop.preferredPH, targetPH: pH)
        let zoneScore = calculateZoneDistance(crop.usdaZones, targetZone: usdaZone)
        let soilScore = calculateSoilSimilarity(crop.soilType, targetSoil: soilType)
        let drainageScore = calculateDrainageSimilarity(crop.preferredSoilDrainage, targetDrainage: drainage)
        
        return (phScore, zoneScore, soilScore, drainageScore)
    }
    
    private func calculatePHDistance(_ cropPH: String, targetPH: Double) -> Double {
        guard let phRange = parsePHRange(cropPH) else { return 0.0 }
        
        if phRange.contains(targetPH) {
            return 1.0
        }
        
        let lower = phRange.lowerBound
        let upper = phRange.upperBound
        
        if targetPH < lower {
            let distance = lower - targetPH
            return max(0.0, 1.0 - (distance * 0.5))
        } else {
            let distance = targetPH - upper
            return max(0.0, 1.0 - (distance * 0.5))
        }
    }
    
    private func calculateZoneDistance(_ cropZones: String, targetZone: String) -> Double {
        guard let targetZoneNum = extractZoneNumber(targetZone) else { return 0.0 }
        
        if let zoneRange = parseZoneRange(cropZones) {
            if targetZoneNum >= zoneRange.lowerBound && targetZoneNum <= zoneRange.upperBound {
                return 1.0
            }
            
            let lower = zoneRange.lowerBound
            let upper = zoneRange.upperBound
            
            if targetZoneNum < lower {
                let distance = Double(lower - targetZoneNum)
                return max(0.0, 1.0 - (distance * 0.2))
            } else {
                let distance = Double(targetZoneNum - upper)
                return max(0.0, 1.0 - (distance * 0.2))
            }
        }
        
        if cropZones.lowercased().contains(targetZone.lowercased()) {
            return 0.8
        }
        
        return 0.0
    }
    
    private func calculateSoilSimilarity(_ cropSoil: String, targetSoil: String) -> Double {
        let cropSoilLower = cropSoil.lowercased().trimmingCharacters(in: .whitespaces)
        let targetSoilLower = targetSoil.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Extract individual soil components from compound soil types
        // e.g., "sand and loam" -> ["sand", "loam"]
        let cropSoilComponents = extractSoilComponents(cropSoilLower)
        let targetSoilComponents = extractSoilComponents(targetSoilLower)
        
        // Normalize each component
        let normalizedCropComponents = cropSoilComponents.map { normalizeSoilName($0) }
        let normalizedTargetComponents = targetSoilComponents.map { normalizeSoilName($0) }
        
        print("      DEBUG Soil Match: crop=\(normalizedCropComponents) vs target=\(normalizedTargetComponents)")
        
        // Exact match after normalization
        if normalizedCropComponents == normalizedTargetComponents {
            print("      -> Exact match: 1.0")
            return 1.0
        }
        
        // Check if any target component is in crop components
        let cropSet = Set(normalizedCropComponents)
        let targetSet = Set(normalizedTargetComponents)
        let intersection = cropSet.intersection(targetSet)
        
        if !intersection.isEmpty {
            print("      -> Component match \(intersection): 0.9")
            return 0.9 // High score if crop can grow in target soil
        }
        
        // No match
        print("      -> No match: 0.1")
        return 0.1
    }
    
    private func normalizeSoilName(_ soil: String) -> String {
        // Normalize similar soil names - standardize to base types
        var normalized = soil.trimmingCharacters(in: .whitespaces)
        
        // Convert variations to standard names
        if normalized.contains("sand") {
            return "sand"
        } else if normalized.contains("clay") {
            return "clay"
        } else if normalized.contains("silt") {
            return "silt"
        } else if normalized.contains("loam") {
            return "loam"
        }
        
        return normalized
    }
    
    private func extractSoilComponents(_ soil: String) -> [String] {
        // Split by "and" or "&" and trim whitespace
        let components = soil
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: "and")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return components
    }
    
    private func calculateDrainageSimilarity(_ cropDrainage: String, targetDrainage: String) -> Double {
        let cropDrainageLower = cropDrainage.lowercased()
        let targetDrainageLower = targetDrainage.lowercased()
        
        if cropDrainageLower == targetDrainageLower {
            return 1.0
        }
        
        if cropDrainageLower.contains(targetDrainageLower) || targetDrainageLower.contains(cropDrainageLower) {
            return 0.8
        }
        
        let drainageTypes = [
            "well-drained": 1.0,
            "moderate": 0.7,
            "poor": 0.3
        ]
        
        let cropDrainageKey = drainageTypes.keys.first { cropDrainageLower.contains($0) }
        let targetDrainageKey = drainageTypes.keys.first { targetDrainageLower.contains($0) }
        
        if let cropKey = cropDrainageKey, let targetKey = targetDrainageKey {
            return min(drainageTypes[cropKey]!, drainageTypes[targetKey]!)
        }
        
        return 0.5
    }
    
    private func parsePHRange(_ phString: String) -> ClosedRange<Double>? {
        let cleaned = phString.replacingOccurrences(of: " ", with: "")
        let separators = CharacterSet(charactersIn: "–-")
        let components = cleaned.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { Double($0) }
        
        guard components.count == 2 else {
            return nil
        }
        
        return components[0]...components[1]
    }
    
    private func parseZoneRange(_ zoneString: String) -> ClosedRange<Int>? {
        let cleaned = zoneString
            .replacingOccurrences(of: "Zones", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "zones", with: "")
        
        let separators = CharacterSet(charactersIn: "–-")
        let components = cleaned.components(separatedBy: separators)
            .map { extractZoneNumber($0) }
            .compactMap { $0 }
        
        guard components.count == 2 else {
            return nil
        }
        
        return components[0]...components[1]
    }
    
    private func extractZoneNumber(_ zoneString: String) -> Int? {
        let numericPart = zoneString.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
        return Int(numericPart)
    }
}
