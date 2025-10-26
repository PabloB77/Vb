import SwiftUI

struct YouTubeView: View {
    @StateObject private var youtubeService = YouTubeDataService.shared
    @State private var searchText = ""
    @State private var videos: [YouTubeVideo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var nextPageToken: String?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search YouTube videos...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchVideos()
                        }
                    
                    Button("Search") {
                        searchVideos()
                    }
                    .disabled(searchText.isEmpty || isLoading)
                }
                .padding()
                
                // Content
                if isLoading {
                    ProgressView("Loading videos...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if videos.isEmpty && !searchText.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No videos found")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if videos.isEmpty {
                    VStack {
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Search for YouTube videos")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(videos) { video in
                                VideoCardView(video: video)
                            }
                            
                            // Load More Button
                            if let nextPageToken = nextPageToken {
                                Button("Load More") {
                                    loadMoreVideos()
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding()
                }
            }
            .navigationTitle("YouTube Search")
        }
    }
    
    private func searchVideos() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        videos = []
        nextPageToken = nil
        
        Task {
            do {
                let response = try await youtubeService.searchVideos(query: searchText)
                await MainActor.run {
                    self.videos = response.items
                    self.nextPageToken = response.nextPageToken
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadMoreVideos() {
        guard let nextPageToken = nextPageToken, !searchText.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let response = try await youtubeService.searchVideos(query: searchText, pageToken: nextPageToken)
                await MainActor.run {
                    self.videos.append(contentsOf: response.items)
                    self.nextPageToken = response.nextPageToken
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct VideoCardView: View {
    let video: YouTubeVideo
    private let youtubeService = YouTubeDataService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            AsyncImage(url: URL(string: youtubeService.getThumbnailURL(from: video.snippet.thumbnails) ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        ProgressView()
                    )
            }
            .cornerRadius(8)
            
            // Video Info
            VStack(alignment: .leading, spacing: 4) {
                Text(video.snippet.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(video.snippet.channelTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(formatDate(video.snippet.publishedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let statistics = video.statistics {
                        Text("\(youtubeService.formatViewCount(statistics.viewCount)) views")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color.primary.colorInvert())
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .abbreviated
        
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    YouTubeView()
}
