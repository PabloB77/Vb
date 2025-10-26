import SwiftUI

struct YouTubeTestView: View {
    @StateObject private var youtubeService = YouTubeDataService.shared
    @State private var testResults: String = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("YouTube API Test")
                .font(.title)
                .fontWeight(.bold)
            
            Button("Test YouTube API") {
                testYouTubeAPI()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            
            if isLoading {
                ProgressView("Testing API...")
            }
            
            ScrollView {
                Text(testResults)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            .frame(maxHeight: 400)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func testYouTubeAPI() {
        isLoading = true
        testResults = "Starting YouTube API test...\n"
        
        Task {
            do {
                testResults += "🔍 Searching for 'gardening tips'...\n"
                let response = try await youtubeService.searchVideos(query: "gardening tips", maxResults: 5)
                
                await MainActor.run {
                    testResults += "✅ API call successful!\n"
                    testResults += "📊 Found \(response.items.count) videos\n\n"
                    
                    for (index, video) in response.items.enumerated() {
                        testResults += "\(index + 1). \(video.snippet.title)\n"
                        testResults += "   Channel: \(video.snippet.channelTitle)\n"
                        testResults += "   Views: \(video.statistics?.viewCount ?? "N/A")\n\n"
                    }
                    
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    testResults += "❌ API call failed: \(error.localizedDescription)\n"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    YouTubeTestView()
}
