import Foundation

// MARK: - YouTube API Response Models

struct YouTubeSearchResponse: Codable {
    let kind: String
    let etag: String
    let nextPageToken: String?
    let regionCode: String?
    let pageInfo: PageInfo
    let items: [YouTubeVideo]
}

struct PageInfo: Codable {
    let totalResults: Int
    let resultsPerPage: Int
}

struct YouTubeVideo: Codable, Identifiable {
    let kind: String
    let etag: String
    let videoIdInfo: VideoID
    let snippet: VideoSnippet
    let statistics: VideoStatistics?
    
    // Computed property for video ID
    var videoId: String {
        return videoIdInfo.videoId
    }
    
    // Required for Identifiable protocol
    var id: String {
        return videoId
    }
    
    enum CodingKeys: String, CodingKey {
        case kind, etag, snippet, statistics
        case videoIdInfo = "id"
    }
}

struct VideoID: Codable {
    let kind: String
    let videoId: String
}

struct VideoSnippet: Codable {
    let publishedAt: String
    let channelId: String
    let title: String
    let description: String
    let thumbnails: Thumbnails
    let channelTitle: String
    let liveBroadcastContent: String
    let publishTime: String?
}

struct Thumbnails: Codable {
    let `default`: Thumbnail?
    let medium: Thumbnail?
    let high: Thumbnail?
    let standard: Thumbnail?
    let maxres: Thumbnail?
}

struct Thumbnail: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

struct VideoStatistics: Codable {
    let viewCount: String?
    let likeCount: String?
    let dislikeCount: String?
    let favoriteCount: String?
    let commentCount: String?
}

// MARK: - YouTube Channel Models

struct YouTubeChannelResponse: Codable {
    let kind: String
    let etag: String
    let pageInfo: PageInfo
    let items: [YouTubeChannel]
}

struct YouTubeChannel: Codable, Identifiable {
    let kind: String
    let etag: String
    let id: String
    let snippet: ChannelSnippet
    let statistics: ChannelStatistics?
    let contentDetails: ChannelContentDetails?
}

struct ChannelSnippet: Codable {
    let title: String
    let description: String
    let customUrl: String?
    let publishedAt: String
    let thumbnails: Thumbnails
    let defaultLanguage: String?
    let localized: ChannelLocalization?
    let country: String?
}

struct ChannelLocalization: Codable {
    let title: String
    let description: String
}

struct ChannelStatistics: Codable {
    let viewCount: String?
    let subscriberCount: String?
    let hiddenSubscriberCount: Bool?
    let videoCount: String?
}

struct ChannelContentDetails: Codable {
    let relatedPlaylists: RelatedPlaylists?
}

struct RelatedPlaylists: Codable {
    let likes: String?
    let favorites: String?
    let uploads: String?
    let watchHistory: String?
    let watchLater: String?
}

// MARK: - YouTube Playlist Models

struct YouTubePlaylistResponse: Codable {
    let kind: String
    let etag: String
    let nextPageToken: String?
    let pageInfo: PageInfo
    let items: [YouTubePlaylist]
}

struct YouTubePlaylist: Codable, Identifiable {
    let kind: String
    let etag: String
    let id: String
    let snippet: PlaylistSnippet
    let contentDetails: PlaylistContentDetails?
}

struct PlaylistSnippet: Codable {
    let publishedAt: String
    let channelId: String
    let title: String
    let description: String
    let thumbnails: Thumbnails
    let channelTitle: String
    let defaultLanguage: String?
    let localized: PlaylistLocalization?
}

struct PlaylistLocalization: Codable {
    let title: String
    let description: String
}

struct PlaylistContentDetails: Codable {
    let itemCount: Int
}

// MARK: - Error Models

struct YouTubeAPIError: Codable, Error {
    let error: APIError
}

struct APIError: Codable {
    let code: Int
    let message: String
    let errors: [ErrorDetail]?
    let status: String
}

struct ErrorDetail: Codable {
    let message: String
    let domain: String
    let reason: String
    let location: String?
    let locationType: String?
}
