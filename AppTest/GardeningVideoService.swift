import Foundation
import Combine
import SwiftUI

class GardeningVideoService: ObservableObject {
    static let shared = GardeningVideoService()
    
    private let youtubeService = YouTubeDataService.shared
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Gardening Video Search Methods
    
    func searchGardeningVideos(for cropName: String, completion: @escaping (Result<[GardeningVideo], Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        print("🔍 Searching for gardening videos for: \(cropName)")
        
        // Create specific search queries for gardening content
        let searchQueries = generateSearchQueries(for: cropName)
        print("📝 Search queries: \(searchQueries)")
        
        Task {
            do {
                var allVideos: [GardeningVideo] = []
                
                // Search with multiple queries to get comprehensive results
                for query in searchQueries.prefix(3) { // Limit to first 3 queries
                    print("🔎 Searching with query: \(query)")
                    let response = try await youtubeService.searchVideos(query: query, maxResults: 4)
                    print("✅ Found \(response.items.count) videos for query: \(query)")
                    
                    // Categorize videos based on query type
                    let categorizedVideos = response.items.map { video in
                        GardeningVideo(from: video, category: categorizeVideo(video, query: query), difficulty: determineDifficulty(video))
                    }
                    
                    allVideos.append(contentsOf: categorizedVideos)
                }
                
                print("📊 Total videos found: \(allVideos.count)")
                
                // Remove duplicates and sort by relevance
                let uniqueVideos = removeDuplicateVideos(allVideos)
                let sortedVideos = sortVideosByRelevance(uniqueVideos, for: cropName)
                
                print("🎯 Final videos after deduplication: \(sortedVideos.count)")
                
                await MainActor.run {
                    self.isLoading = false
                    completion(.success(sortedVideos))
                }
            } catch {
                print("❌ Error searching videos: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func searchGeneralGardeningVideos(completion: @escaping (Result<[GardeningVideo], Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let generalQueries = [
            "gardening tips for beginners",
            "how to grow vegetables at home",
            "organic gardening techniques",
            "garden planning and design",
            "plant care and maintenance"
        ]
        
        Task {
            do {
                var allVideos: [GardeningVideo] = []
                
                for query in generalQueries {
                    let response = try await youtubeService.searchVideos(query: query, maxResults: 3)
                    let categorizedVideos = response.items.map { video in
                        GardeningVideo(from: video, category: categorizeVideo(video, query: query), difficulty: determineDifficulty(video))
                    }
                    allVideos.append(contentsOf: categorizedVideos)
                }
                
                let uniqueVideos = removeDuplicateVideos(allVideos)
                
                await MainActor.run {
                    self.isLoading = false
                    completion(.success(uniqueVideos))
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Video Categorization Methods
    
    private func categorizeVideo(_ video: YouTubeVideo, query: String) -> VideoCategoryType {
        let title = video.snippet.title.lowercased()
        let description = video.snippet.description.lowercased()
        let queryLower = query.lowercased()
        
        // Growing guides
        if queryLower.contains("how to grow") || queryLower.contains("growing guide") || 
           title.contains("how to grow") || title.contains("growing") || title.contains("planting") {
            return .growing
        }
        
        // Plant care
        if queryLower.contains("care") || queryLower.contains("maintenance") ||
           title.contains("care") || title.contains("maintenance") || title.contains("watering") ||
           title.contains("fertilizing") || title.contains("pruning") {
            return .care
        }
        
        // Garden design
        if queryLower.contains("design") || queryLower.contains("layout") ||
           title.contains("design") || title.contains("layout") || title.contains("planning") ||
           title.contains("arrangement") {
            return .design
        }
        
        // Harvesting
        if queryLower.contains("harvest") || queryLower.contains("picking") ||
           title.contains("harvest") || title.contains("picking") || title.contains("collecting") {
            return .harvesting
        }
        
        // Troubleshooting
        if queryLower.contains("problem") || queryLower.contains("issue") || queryLower.contains("disease") ||
           queryLower.contains("pest") || queryLower.contains("troubleshoot") ||
           title.contains("problem") || title.contains("issue") || title.contains("disease") ||
           title.contains("pest") || title.contains("troubleshoot") || title.contains("fix") {
            return .troubleshooting
        }
        
        // Default to growing if no specific category matches
        return .growing
    }
    
    private func determineDifficulty(_ video: YouTubeVideo) -> DifficultyLevel {
        let title = video.snippet.title.lowercased()
        let description = video.snippet.description.lowercased()
        
        // Advanced keywords
        if title.contains("advanced") || title.contains("expert") || title.contains("professional") ||
           title.contains("master") || title.contains("complex") || title.contains("technical") {
            return .advanced
        }
        
        // Intermediate keywords
        if title.contains("intermediate") || title.contains("experienced") || title.contains("detailed") ||
           title.contains("step by step") || title.contains("complete guide") {
            return .intermediate
        }
        
        // Beginner keywords
        if title.contains("beginner") || title.contains("easy") || title.contains("simple") ||
           title.contains("basic") || title.contains("start") || title.contains("introduction") {
            return .beginner
        }
        
        // Default to beginner for gardening content
        return .beginner
    }
    
    // MARK: - Helper Methods
    
    private func generateSearchQueries(for cropName: String) -> [String] {
        let baseQueries = [
            "how to grow \(cropName) gardening",
            "\(cropName) growing guide",
            "planting \(cropName) tips",
            "\(cropName) care instructions",
            "growing \(cropName) at home"
        ]
        
        // Add specific queries based on crop type
        let specificQueries = getSpecificQueries(for: cropName)
        
        return baseQueries + specificQueries
    }
    
    private func getSpecificQueries(for cropName: String) -> [String] {
        let lowercasedCrop = cropName.lowercased()
        
        var queries: [String] = []
        
        // Vegetable-specific queries
        if lowercasedCrop.contains("tomato") || lowercasedCrop.contains("tomatoes") {
            queries.append(contentsOf: [
                "tomato growing from seed",
                "tomato plant care pruning",
                "tomato diseases and pests"
            ])
        }
        
        if lowercasedCrop.contains("lettuce") || lowercasedCrop.contains("spinach") {
            queries.append(contentsOf: [
                "leafy greens growing",
                "lettuce growing tips",
                "harvesting leafy vegetables"
            ])
        }
        
        if lowercasedCrop.contains("herb") || lowercasedCrop.contains("basil") || lowercasedCrop.contains("mint") {
            queries.append(contentsOf: [
                "herb garden growing",
                "indoor herb gardening",
                "herb harvesting and drying"
            ])
        }
        
        // Flower-specific queries
        if lowercasedCrop.contains("flower") || lowercasedCrop.contains("rose") || lowercasedCrop.contains("sunflower") {
            queries.append(contentsOf: [
                "flower garden design",
                "flowering plant care",
                "cut flower growing"
            ])
        }
        
        // Fruit-specific queries
        if lowercasedCrop.contains("berry") || lowercasedCrop.contains("strawberry") || lowercasedCrop.contains("blueberry") {
            queries.append(contentsOf: [
                "berry growing guide",
                "fruit garden planning",
                "berry plant maintenance"
            ])
        }
        
        return queries
    }
    
    private func removeDuplicateVideos(_ videos: [GardeningVideo]) -> [GardeningVideo] {
        var seen = Set<String>()
        return videos.filter { video in
            if seen.contains(video.id) {
                return false
            } else {
                seen.insert(video.id)
                return true
            }
        }
    }
    
    private func sortVideosByRelevance(_ videos: [GardeningVideo], for cropName: String) -> [GardeningVideo] {
        return videos.sorted { video1, video2 in
            let title1 = video1.title.lowercased()
            let title2 = video2.title.lowercased()
            let cropLower = cropName.lowercased()
            
            // Prioritize videos with crop name in title
            let hasCrop1 = title1.contains(cropLower)
            let hasCrop2 = title2.contains(cropLower)
            
            if hasCrop1 && !hasCrop2 {
                return true
            } else if !hasCrop1 && hasCrop2 {
                return false
            }
            
            // Then prioritize by view count
            let views1 = Int(video1.viewCount) ?? 0
            let views2 = Int(video2.viewCount) ?? 0
            
            return views1 > views2
        }
    }
    
    // MARK: - Video Categories
    
    func getVideoCategories() -> [VideoCategory] {
        return [
            VideoCategory(name: "Growing Guides", icon: "leaf.fill", color: .green),
            VideoCategory(name: "Plant Care", icon: "drop.fill", color: .blue),
            VideoCategory(name: "Garden Design", icon: "paintbrush.fill", color: .purple),
            VideoCategory(name: "Harvesting", icon: "basket.fill", color: .orange),
            VideoCategory(name: "Troubleshooting", icon: "wrench.fill", color: .red)
        ]
    }
}

// MARK: - Video Category Model

struct VideoCategory {
    let name: String
    let icon: String
    let color: Color
}

extension VideoCategory: Identifiable {
    var id: String { name }
}
