import SwiftUI

struct LearnView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
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
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .foregroundColor(AppColorScheme.primary)
                            .fontWeight(.semibold)
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
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 70, height: 70)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.15), color.opacity(0.25)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(AppColorScheme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColorScheme.textSecondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isHovered ? AppColorScheme.primary.opacity(0.03) : AppColorScheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isHovered ? color.opacity(0.3) : AppColorScheme.border,
                    lineWidth: isHovered ? 2 : 1
                )
        )
        .shadow(
            color: isHovered ? color.opacity(0.1) : AppColorScheme.overlayMedium,
            radius: isHovered ? 12 : 6,
            x: 0,
            y: 4
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
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
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.15), color.opacity(0.25)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(10)
            
            Text(tip)
                .font(.system(size: 15))
                .foregroundColor(AppColorScheme.textPrimary)
                .lineLimit(3)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isHovered ? AppColorScheme.primary.opacity(0.03) : AppColorScheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isHovered ? color.opacity(0.3) : AppColorScheme.border,
                    lineWidth: isHovered ? 2 : 1
                )
        )
        .shadow(
            color: isHovered ? color.opacity(0.1) : AppColorScheme.overlayLight,
            radius: isHovered ? 8 : 4,
            x: 0,
            y: 2
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

