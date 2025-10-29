import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

// MARK: - Saved Plant Model
struct SavedPlant: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let scientificName: String?
    let description: String
    let estimatedRevenue: String
    let soilMatchAnalysis: String
    let economicProfile: String
    let keyAdvantage: String
    let imageURL: String?
    let addedAt: Date
    let userId: String
    
    init(id: String = UUID().uuidString,
         name: String,
         scientificName: String? = nil,
         description: String,
         estimatedRevenue: String,
         soilMatchAnalysis: String,
         economicProfile: String,
         keyAdvantage: String,
         imageURL: String? = nil,
         addedAt: Date = Date(),
         userId: String) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.description = description
        self.estimatedRevenue = estimatedRevenue
        self.soilMatchAnalysis = soilMatchAnalysis
        self.economicProfile = economicProfile
        self.keyAdvantage = keyAdvantage
        self.imageURL = imageURL
        self.addedAt = addedAt
        self.userId = userId
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "description": description,
            "estimatedRevenue": estimatedRevenue,
            "soilMatchAnalysis": soilMatchAnalysis,
            "economicProfile": economicProfile,
            "keyAdvantage": keyAdvantage,
            "addedAt": Timestamp(date: addedAt),
            "userId": userId
        ]
        if let scientificName = scientificName {
            dict["scientificName"] = scientificName
        }
        if let imageURL = imageURL {
            dict["imageURL"] = imageURL
        }
        return dict
    }
}

// MARK: - My Garden Manager
class MyGardenManager: ObservableObject {
    @Published var savedPlants: [SavedPlant] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var userId: String?
    
    func setUserId(_ userId: String) {
        self.userId = userId
    }
    
    func addPlant(crop: ParsedCrop, userId: String) {
        guard !savedPlants.contains(where: { $0.name.lowercased() == crop.name.lowercased() }) else {
            errorMessage = "This plant is already in your garden"
            return
        }
        
        let plant = SavedPlant(
            name: crop.name,
            scientificName: extractScientificName(from: crop.fullText),
            description: extractDescription(from: crop.fullText),
            estimatedRevenue: crop.estimatedRevenue,
            soilMatchAnalysis: extractSoilMatch(from: crop.fullText),
            economicProfile: extractEconomicProfile(from: crop.fullText),
            keyAdvantage: extractKeyAdvantage(from: crop.fullText),
            imageURL: nil,
            userId: userId
        )
        
        let document = db.collection("myGarden").document()
        document.setData(plant.toDictionary()) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error saving plant: \(error.localizedDescription)"
                }
            } else {
                DispatchQueue.main.async {
                    self.savedPlants.append(plant)
                }
            }
        }
    }
    
    func removePlant(_ plant: SavedPlant) {
        guard let userId = userId else { return }
        
        db.collection("myGarden")
            .whereField("userId", isEqualTo: userId)
            .whereField("name", isEqualTo: plant.name)
            .getDocuments { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error removing plant: \(error.localizedDescription)"
                    }
                    return
                }
                
                snapshot?.documents.forEach { document in
                    document.reference.delete()
                }
                
                DispatchQueue.main.async {
                    self.savedPlants.removeAll { $0.id == plant.id }
                }
            }
    }
    
    func loadGarden(userId: String) {
        isLoading = true
        self.userId = userId
        
        print("DEBUG: Loading garden for userId: \(userId)")
        
        db.collection("myGarden")
            .whereField("userId", isEqualTo: userId)
            .order(by: "addedAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("DEBUG: Error loading garden: \(error.localizedDescription)")
                        self.errorMessage = "Error loading garden: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("DEBUG: No documents found in myGarden collection")
                        return
                    }
                    
                    print("DEBUG: Found \(documents.count) plants in garden")
                    self.savedPlants = documents.compactMap { doc in
                        SavedPlant.fromDocument(doc)
                    }
                    print("DEBUG: Loaded \(self.savedPlants.count) plants")
                }
            }
    }
    
    private func extractScientificName(from text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            if line.contains("(") && line.contains(")") {
                let start = line.range(of: "(")?.upperBound
                let end = line.range(of: ")")?.lowerBound
                if let start = start, let end = end {
                    return String(line[start..<end])
                }
            }
        }
        return nil
    }
    
    private func extractDescription(from text: String) -> String {
        if let range = text.range(of: "Crop Description:") {
            let afterDescription = text[range.upperBound...]
            if let endRange = afterDescription.range(of: "Soil") ?? afterDescription.range(of: "Economic") {
                return String(afterDescription[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return text
    }
    
    private func extractSoilMatch(from text: String) -> String {
        if let range = text.range(of: "Soil Match Analysis:") {
            let afterSoil = text[range.upperBound...]
            if let endRange = afterSoil.range(of: "Economic") {
                return String(afterSoil[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }
    
    private func extractEconomicProfile(from text: String) -> String {
        if let range = text.range(of: "Economic Profile:") {
            let afterEconomic = text[range.upperBound...]
            if let endRange = afterEconomic.range(of: "Estimated") ?? afterEconomic.range(of: "Key") {
                return String(afterEconomic[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }
    
    private func extractKeyAdvantage(from text: String) -> String {
        if let range = text.range(of: "Key Advantage:") {
            return String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
}

// Extension to decode from Firestore
extension SavedPlant {
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let description = dictionary["description"] as? String,
              let estimatedRevenue = dictionary["estimatedRevenue"] as? String,
              let soilMatchAnalysis = dictionary["soilMatchAnalysis"] as? String,
              let economicProfile = dictionary["economicProfile"] as? String,
              let keyAdvantage = dictionary["keyAdvantage"] as? String,
              let addedAt = (dictionary["addedAt"] as? Timestamp)?.dateValue(),
              let userId = dictionary["userId"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.scientificName = dictionary["scientificName"] as? String
        self.description = description
        self.estimatedRevenue = estimatedRevenue
        self.soilMatchAnalysis = soilMatchAnalysis
        self.economicProfile = economicProfile
        self.keyAdvantage = keyAdvantage
        self.imageURL = dictionary["imageURL"] as? String
        self.addedAt = addedAt
        self.userId = userId
    }
    
    static func fromDocument(_ document: QueryDocumentSnapshot) -> SavedPlant? {
        let data = document.data()
        guard let name = data["name"] as? String,
              let description = data["description"] as? String,
              let estimatedRevenue = data["estimatedRevenue"] as? String,
              let soilMatchAnalysis = data["soilMatchAnalysis"] as? String,
              let economicProfile = data["economicProfile"] as? String,
              let keyAdvantage = data["keyAdvantage"] as? String,
              let timestamp = data["addedAt"] as? Timestamp,
              let userId = data["userId"] as? String else {
            return nil
        }
        
        return SavedPlant(
            id: document.documentID,
            name: name,
            scientificName: data["scientificName"] as? String,
            description: description,
            estimatedRevenue: estimatedRevenue,
            soilMatchAnalysis: soilMatchAnalysis,
            economicProfile: economicProfile,
            keyAdvantage: keyAdvantage,
            imageURL: data["imageURL"] as? String,
            addedAt: timestamp.dateValue(),
            userId: userId
        )
    }
}

