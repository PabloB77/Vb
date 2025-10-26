import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyGardenView: View {
    @StateObject private var gardenManager = MyGardenManager()
    @State private var selectedPlant: SavedPlant?
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColorScheme.backgroundGradient
                    .ignoresSafeArea()
                
                if gardenManager.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading your garden...")
                            .font(.headline)
                            .foregroundColor(AppColorScheme.textSecondary)
                    }
                } else if gardenManager.savedPlants.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(gardenManager.savedPlants) { plant in
                                PlantCard(plant: plant)
                                    .onTapGesture {
                                        selectedPlant = plant
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Garden")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .foregroundColor(AppColorScheme.primary)
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant, gardenManager: gardenManager)
            }
            .onAppear {
                if let userId = authViewModel.user?.uid {
                    gardenManager.loadGarden(userId: userId)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 80))
                .foregroundColor(AppColorScheme.primary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("Your Garden is Empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                Text("Add plants from crop recommendations to start building your garden")
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Plant Card
struct PlantCard: View {
    let plant: SavedPlant
    @State private var plantImage: NSImage?
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Image placeholder with modern styling
            if let image = plantImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .cornerRadius(14)
                    .shadow(color: AppColorScheme.primary.opacity(0.2), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [AppColorScheme.primary.opacity(0.3), AppColorScheme.accent.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColorScheme.primary.opacity(0.15),
                                AppColorScheme.accent.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 36))
                            .foregroundColor(AppColorScheme.primary)
                    )
                    .shadow(color: AppColorScheme.primary.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(plant.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColorScheme.textPrimary)
                    .lineLimit(2)
                
                if let scientific = plant.scientificName {
                    Text(scientific)
                        .font(.system(size: 13))
                        .foregroundColor(AppColorScheme.textSecondary)
                        .italic()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColorScheme.primary)
                    Text(plant.estimatedRevenue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColorScheme.primary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(AppColorScheme.textSecondary)
                    Text(formatDate(plant.addedAt))
                        .font(.system(size: 12))
                        .foregroundColor(AppColorScheme.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColorScheme.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isHovered ? AppColorScheme.primary.opacity(0.03) : AppColorScheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isHovered ? AppColorScheme.primary.opacity(0.2) : AppColorScheme.border,
                    lineWidth: isHovered ? 2 : 1
                )
        )
        .shadow(
            color: isHovered ? AppColorScheme.primary.opacity(0.1) : AppColorScheme.overlayMedium,
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Plant Detail View
struct PlantDetailView: View {
    let plant: SavedPlant
    let gardenManager: MyGardenManager
    @Environment(\.dismiss) private var dismiss
    @State private var plantImage: NSImage?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        if let image = plantImage {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 200, maxHeight: 200)
                                .cornerRadius(16)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColorScheme.primary.opacity(0.1))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(AppColorScheme.primary)
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        SectionTitle(title: "Details")
                        
                        DetailSection(title: "Revenue Estimate", content: plant.estimatedRevenue)
                        DetailSection(title: "Soil Match", content: plant.soilMatchAnalysis)
                        DetailSection(title: "Economic Profile", content: plant.economicProfile)
                        DetailSection(title: "Key Advantage", content: plant.keyAdvantage)
                        DetailSection(title: "Description", content: plant.description)
                    }
                    .padding()
                    .background(AppColorScheme.cardBackground)
                    .cornerRadius(16)
                    .padding()
                }
            }
            .navigationTitle(plant.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .foregroundColor(AppColorScheme.primary)
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("Remove") {
                        gardenManager.removePlant(plant)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views
struct SectionTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(AppColorScheme.textPrimary)
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColorScheme.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(AppColorScheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

