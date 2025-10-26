import SwiftUI
import WebKit

struct VideoPlayerView: View {
    let video: GardeningVideo
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Video Player
            YouTubeWebView(
                videoId: video.id,
                isLoading: $isLoading
            )
            .frame(height: 300)
            
            // Video Info
            VStack(alignment: .leading, spacing: 12) {
                Text(video.title)
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack {
                    Text(video.channelTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatViewCount(video.viewCount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Categories
                HStack(spacing: 8) {
                    CategoryBadge(category: video.category)
                    DifficultyBadge(difficulty: video.difficulty)
                }
                .padding(.horizontal)
                
                // Description
                ScrollView {
                    Text(video.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 150)
            }
            .padding(.vertical)
        }
        .navigationTitle("Video Player")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
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

struct YouTubeWebView: NSViewRepresentable {
    let videoId: String
    @Binding var isLoading: Bool
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { margin: 0; padding: 0; background: #000; }
                .video-container { position: relative; width: 100%; height: 0; padding-bottom: 56.25%; }
                .video-container iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe 
                    src="https://www.youtube.com/embed/\(videoId)?autoplay=1&rel=0&modestbranding=1"
                    frameborder="0" 
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
                    allowfullscreen>
                </iframe>
            </div>
        </body>
        </html>
        """
        
        webView.loadHTMLString(embedHTML, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: YouTubeWebView
        
        init(_ parent: YouTubeWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
    }
}

#Preview {
    VideoPlayerView(video: GardeningVideo(
        from: YouTubeVideo(
            kind: "",
            etag: "",
            videoIdInfo: VideoID(kind: "", videoId: "dQw4w9WgXcQ"),
            snippet: VideoSnippet(
                publishedAt: "",
                channelId: "",
                title: "Sample Video",
                description: "Sample description",
                thumbnails: Thumbnails(default: nil, medium: nil, high: nil, standard: nil, maxres: nil),
                channelTitle: "Sample Channel",
                liveBroadcastContent: "",
                publishTime: nil
            ),
            statistics: nil
        )
    ))
}
