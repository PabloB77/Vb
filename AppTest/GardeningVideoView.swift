import SwiftUI

struct GardeningVideoView: View {
    let cropName: String
    @StateObject private var videoService = GardeningVideoService.shared
    @State private var videos: [GardeningVideo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedVideo: GardeningVideo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Gardening Videos")
                        .font(.headline)
                        .foregroundColor(AppColorScheme.textPrimary)
                    Text("Learn how to grow \(cropName)")
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            
            // Content
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading gardening videos...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("Unable to load videos")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        loadVideos()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if videos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("No videos found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Try searching for a different crop")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(VideoCategoryType.allCases, id: \.self) { category in
                            let categoryVideos = videos.filter { $0.category == category }
                            
                            if !categoryVideos.isEmpty {
                                VideoCategorySection(
                                    category: category,
                                    videos: categoryVideos,
                                    onVideoTap: { video in
                                        selectedVideo = video
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            loadVideos()
        }
        .sheet(item: $selectedVideo) { video in
            VideoPlayerView(video: video)
        }
    }
    
    
    private func loadVideos() {
        isLoading = true
        errorMessage = nil
        
        print("🎬 Loading videos for crop: \(cropName)")
        
        videoService.searchGardeningVideos(for: cropName) { result in
            switch result {
            case .success(let fetchedVideos):
                print("✅ Successfully loaded \(fetchedVideos.count) videos")
                self.videos = fetchedVideos
                self.isLoading = false
            case .failure(let error):
                print("❌ Failed to load videos: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

struct VideoCategorySection: View {
    let category: VideoCategoryType
    let videos: [GardeningVideo]
    let onVideoTap: (GardeningVideo) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Header
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(category.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("\(videos.count) video\(videos.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Videos Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(videos) { video in
                        CompactVideoCardView(video: video) {
                            onVideoTap(video)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(category.color.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CompactVideoCardView: View {
    let video: GardeningVideo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
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
                .frame(width: 160, height: 90)
                .cornerRadius(8)
                
                // Video Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    Text(video.channelTitle)
                        .font(.caption2)
                        .foregroundColor(AppColorScheme.textSecondary)
                        .lineLimit(1)
                    
                    // Difficulty Badge
                    HStack {
                        DifficultyBadge(difficulty: video.difficulty)
                        Spacer()
                    }
                }
                .frame(width: 160)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GardeningVideoCardView: View {
    let video: GardeningVideo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
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
                .frame(width: 120, height: 68)
                .cornerRadius(8)
                
                // Video Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    Text(video.channelTitle)
                        .font(.caption)
                        .foregroundColor(AppColorScheme.textSecondary)
                    
                    HStack {
                        // Category Badge
                        HStack(spacing: 4) {
                            Image(systemName: video.category.icon)
                                .font(.caption2)
                            Text(video.category.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(video.category.color.opacity(0.2))
                        .foregroundColor(video.category.color)
                        .cornerRadius(4)
                        
                        // Difficulty Badge
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(video.difficulty.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(video.difficulty.color.opacity(0.2))
                        .foregroundColor(video.difficulty.color)
                        .cornerRadius(4)
                        
                        Spacer()
                    }
                    
                    // Stats
                    HStack {
                        Text(formatViewCount(video.viewCount))
                            .font(.caption)
                            .foregroundColor(AppColorScheme.textSecondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(AppColorScheme.textSecondary)
                        
                        Text(formatDate(video.publishedAt))
                            .font(.caption)
                            .foregroundColor(AppColorScheme.textSecondary)
                    }
                }
                
                Spacer()
                
                // Play Button
                VStack {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Play")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(AppColorScheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatViewCount(_ count: String) -> String {
        guard let number = Int(count) else { return "0 views" }
        
        if number >= 1_000_000 {
            return String(format: "%.1fM views", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK views", Double(number) / 1_000)
        } else {
            return "\(number) views"
        }
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

struct VideoDetailView: View {
    let video: GardeningVideo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Video Thumbnail (placeholder for actual video player)
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(
                            VStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                Text("Tap to open in YouTube")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        )
                }
                .cornerRadius(12)
                .onTapGesture {
                    openInYouTube()
                }
                
                // Video Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(video.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(video.channelTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatViewCount(video.viewCount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Categories
                    HStack(spacing: 8) {
                        CategoryBadge(category: video.category)
                        DifficultyBadge(difficulty: video.difficulty)
                    }
                    
                    // Description
                    Text(video.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(5)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Video Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Open in YouTube") {
                        openInYouTube()
                    }
                }
            }
        }
    }
    
    private func openInYouTube() {
        if let url = URL(string: video.videoURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func formatViewCount(_ count: String) -> String {
        guard let number = Int(count) else { return "0 views" }
        
        if number >= 1_000_000 {
            return String(format: "%.1fM views", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK views", Double(number) / 1_000)
        } else {
            return "\(number) views"
        }
    }
}

struct CategoryBadge: View {
    let category: VideoCategoryType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption)
            Text(category.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.2))
        .foregroundColor(category.color)
        .cornerRadius(6)
    }
}

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
            Text(difficulty.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(difficulty.color.opacity(0.2))
        .foregroundColor(difficulty.color)
        .cornerRadius(6)
    }
}

#Preview {
    GardeningVideoView(cropName: "Tomatoes")
}
