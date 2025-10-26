import Foundation
import SwiftUI

// MARK: - Gardening Video Models

struct GardeningVideo: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let videoURL: String
    let channelTitle: String
    let publishedAt: String
    let viewCount: String
    let duration: String?
    let category: VideoCategoryType
    let difficulty: DifficultyLevel
    let season: Season?
    
    init(from youtubeVideo: YouTubeVideo, category: VideoCategoryType = .general, difficulty: DifficultyLevel = .beginner) {
        self.id = youtubeVideo.videoId
        self.title = youtubeVideo.snippet.title
        self.description = youtubeVideo.snippet.description
        self.thumbnailURL = YouTubeDataService.shared.getThumbnailURL(from: youtubeVideo.snippet.thumbnails) ?? ""
        self.videoURL = "https://www.youtube.com/watch?v=\(youtubeVideo.videoId)"
        self.channelTitle = youtubeVideo.snippet.channelTitle
        self.publishedAt = youtubeVideo.snippet.publishedAt
        self.viewCount = youtubeVideo.statistics?.viewCount ?? "0"
        self.duration = nil // YouTube API doesn't provide duration in search results
        self.category = category
        self.difficulty = difficulty
        self.season = nil
    }
}

// MARK: - Video Category Types

enum VideoCategoryType: String, CaseIterable, Codable, Identifiable {
    case growing = "growing"
    case care = "care"
    case design = "design"
    case harvesting = "harvesting"
    case troubleshooting = "troubleshooting"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .growing: return "Growing Guides"
        case .care: return "Plant Care"
        case .design: return "Garden Design"
        case .harvesting: return "Harvesting"
        case .troubleshooting: return "Troubleshooting"
        case .general: return "General"
        }
    }
    
    var icon: String {
        switch self {
        case .growing: return "leaf.fill"
        case .care: return "drop.fill"
        case .design: return "paintbrush.fill"
        case .harvesting: return "basket.fill"
        case .troubleshooting: return "wrench.fill"
        case .general: return "play.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .growing: return .green
        case .care: return .blue
        case .design: return .purple
        case .harvesting: return .orange
        case .troubleshooting: return .red
        case .general: return .gray
        }
    }
    
    var id: String { rawValue }
}

// MARK: - Difficulty Levels

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Seasons

enum Season: String, CaseIterable, Codable {
    case spring = "spring"
    case summer = "summer"
    case fall = "fall"
    case winter = "winter"
    
    var displayName: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .fall: return "Fall"
        case .winter: return "Winter"
        }
    }
    
    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .fall: return "leaf.arrow.circlepath"
        case .winter: return "snowflake"
        }
    }
}

// MARK: - Video Playlist

struct GardeningPlaylist: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let videoCount: Int
    let videos: [GardeningVideo]
    let category: VideoCategoryType
    let difficulty: DifficultyLevel
    let estimatedDuration: String
    
    init(title: String, description: String, videos: [GardeningVideo], category: VideoCategoryType = .general, difficulty: DifficultyLevel = .beginner) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.thumbnailURL = videos.first?.thumbnailURL ?? ""
        self.videoCount = videos.count
        self.videos = videos
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = "\(videos.count * 10) min" // Estimate 10 minutes per video
    }
}

// MARK: - Video Search Filters

struct VideoSearchFilters {
    var category: VideoCategoryType?
    var difficulty: DifficultyLevel?
    var season: Season?
    var maxDuration: Int? // in minutes
    var minViewCount: Int?
    var publishedAfter: Date?
    
    static let `default` = VideoSearchFilters()
}

// MARK: - Video Analytics

struct VideoAnalytics {
    let videoId: String
    let watchTime: TimeInterval
    let completionRate: Double
    let lastWatched: Date
    let isBookmarked: Bool
    let rating: Int? // 1-5 stars
    
    init(videoId: String) {
        self.videoId = videoId
        self.watchTime = 0
        self.completionRate = 0
        self.lastWatched = Date()
        self.isBookmarked = false
        self.rating = nil
    }
}

// MARK: - Video Recommendations

struct VideoRecommendation {
    let video: GardeningVideo
    let reason: String
    let confidence: Double // 0.0 to 1.0
    let tags: [String]
    
    init(video: GardeningVideo, reason: String, confidence: Double = 0.8, tags: [String] = []) {
        self.video = video
        self.reason = reason
        self.confidence = confidence
        self.tags = tags
    }
}
