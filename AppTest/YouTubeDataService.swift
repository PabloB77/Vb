import Foundation
import Combine

class YouTubeDataService: ObservableObject {
    static let shared = YouTubeDataService()
    
    private let baseURL = "https://www.googleapis.com/youtube/v3"
    private var apiKey: String = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        loadAPIKey()
    }
    
    private func loadAPIKey() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["YOUTUBE_API_KEY"] as? String else {
            print("❌ YouTube API key not found in GoogleService-Info.plist")
            return
        }
        self.apiKey = apiKey
        print("✅ YouTube API key loaded successfully")
    }
    
    // MARK: - Search Videos
    
    func searchVideos(query: String, maxResults: Int = 25, pageToken: String? = nil) async throws -> YouTubeSearchResponse {
        guard !apiKey.isEmpty else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "API key not configured", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let pageToken = pageToken {
            components.queryItems?.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        
        guard let url = components.url else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "Invalid URL", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeAPIError(error: APIError(code: 500, message: "Invalid response", errors: nil, status: "INTERNAL_ERROR"))
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try JSONDecoder().decode(YouTubeAPIError.self, from: data)
            throw errorResponse
        }
        
        return try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
    }
    
    // MARK: - Get Video Details
    
    func getVideoDetails(videoIds: [String]) async throws -> YouTubeSearchResponse {
        guard !apiKey.isEmpty else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "API key not configured", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        let videoIdsString = videoIds.joined(separator: ",")
        
        var components = URLComponents(string: "\(baseURL)/videos")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,statistics"),
            URLQueryItem(name: "id", value: videoIdsString),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "Invalid URL", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeAPIError(error: APIError(code: 500, message: "Invalid response", errors: nil, status: "INTERNAL_ERROR"))
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try JSONDecoder().decode(YouTubeAPIError.self, from: data)
            throw errorResponse
        }
        
        return try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
    }
    
    // MARK: - Get Channel Information
    
    func getChannelInfo(channelId: String) async throws -> YouTubeChannelResponse {
        guard !apiKey.isEmpty else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "API key not configured", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        var components = URLComponents(string: "\(baseURL)/channels")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,statistics,contentDetails"),
            URLQueryItem(name: "id", value: channelId),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "Invalid URL", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeAPIError(error: APIError(code: 500, message: "Invalid response", errors: nil, status: "INTERNAL_ERROR"))
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try JSONDecoder().decode(YouTubeAPIError.self, from: data)
            throw errorResponse
        }
        
        return try JSONDecoder().decode(YouTubeChannelResponse.self, from: data)
    }
    
    // MARK: - Get Channel Playlists
    
    func getChannelPlaylists(channelId: String, maxResults: Int = 25, pageToken: String? = nil) async throws -> YouTubePlaylistResponse {
        guard !apiKey.isEmpty else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "API key not configured", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        var components = URLComponents(string: "\(baseURL)/playlists")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails"),
            URLQueryItem(name: "channelId", value: channelId),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let pageToken = pageToken {
            components.queryItems?.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        
        guard let url = components.url else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "Invalid URL", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeAPIError(error: APIError(code: 500, message: "Invalid response", errors: nil, status: "INTERNAL_ERROR"))
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try JSONDecoder().decode(YouTubeAPIError.self, from: data)
            throw errorResponse
        }
        
        return try JSONDecoder().decode(YouTubePlaylistResponse.self, from: data)
    }
    
    // MARK: - Get Playlist Items
    
    func getPlaylistItems(playlistId: String, maxResults: Int = 25, pageToken: String? = nil) async throws -> YouTubeSearchResponse {
        guard !apiKey.isEmpty else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "API key not configured", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        var components = URLComponents(string: "\(baseURL)/playlistItems")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "playlistId", value: playlistId),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let pageToken = pageToken {
            components.queryItems?.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        
        guard let url = components.url else {
            throw YouTubeAPIError(error: APIError(code: 400, message: "Invalid URL", errors: nil, status: "INVALID_ARGUMENT"))
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeAPIError(error: APIError(code: 500, message: "Invalid response", errors: nil, status: "INTERNAL_ERROR"))
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorResponse = try JSONDecoder().decode(YouTubeAPIError.self, from: data)
            throw errorResponse
        }
        
        return try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
    }
    
    // MARK: - Helper Methods
    
    func formatViewCount(_ count: String?) -> String {
        guard let count = count, let number = Int(count) else { return "0" }
        
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return count
        }
    }
    
    func formatSubscriberCount(_ count: String?) -> String {
        guard let count = count, let number = Int(count) else { return "0" }
        
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return count
        }
    }
    
    func getThumbnailURL(from thumbnails: Thumbnails, quality: ThumbnailQuality = .high) -> String? {
        switch quality {
        case .default:
            return thumbnails.default?.url
        case .medium:
            return thumbnails.medium?.url
        case .high:
            return thumbnails.high?.url
        case .standard:
            return thumbnails.standard?.url
        case .maxres:
            return thumbnails.maxres?.url
        }
    }
}

enum ThumbnailQuality {
    case `default`
    case medium
    case high
    case standard
    case maxres
}
