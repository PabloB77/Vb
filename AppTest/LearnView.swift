import SwiftUI

struct LearnView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HeaderSection()
                        
                        LearningResourcesSection()
                        
                        TipsSection()
                    }
                    .padding()
                }
            }
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColorScheme.primary)
            
            Text("Learn About Farming")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColorScheme.textPrimary)
            
            Text("Discover best practices and tips for successful growing")
                .font(.subheadline)
                .foregroundColor(AppColorScheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct LearningResourcesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resources")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColorScheme.textPrimary)
            
            ResourceCard(
                icon: "leaf.fill",
                title: "Soil Preparation",
                description: "Learn how to prepare your soil for optimal plant growth",
                color: AppColorScheme.primary
            )
            
            ResourceCard(
                icon: "drop.fill",
                title: "Watering Best Practices",
                description: "Understand proper irrigation techniques",
                color: AppColorScheme.accent
            )
            
            ResourceCard(
                icon: "sun.max.fill",
                title: "Seasonal Planning",
                description: "Plan your crops based on seasons and climate",
                color: AppColorScheme.primary
            )
        }
    }
}

struct ResourceCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColorScheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColorScheme.border, lineWidth: 1)
        )
    }
}

struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Tips")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColorScheme.textPrimary)
            
            TipCard(
                icon: "checkmark.circle.fill",
                tip: "Test your soil pH regularly for optimal results",
                color: AppColorScheme.primary
            )
            
            TipCard(
                icon: "checkmark.circle.fill",
                tip: "Rotate crops to maintain soil health",
                color: AppColorScheme.accent
            )
            
            TipCard(
                icon: "checkmark.circle.fill",
                tip: "Choose crops suited for your hardiness zone",
                color: AppColorScheme.primary
            )
        }
    }
}

struct TipCard: View {
    let icon: String
    let tip: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(tip)
                .font(.body)
                .foregroundColor(AppColorScheme.textPrimary)
            
            Spacer()
        }
        .padding()
        .background(AppColorScheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColorScheme.border, lineWidth: 1)
        )
    }
}

