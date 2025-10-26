import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyGardenView: View {
    @StateObject private var gardenManager = MyGardenManager()
    @State private var selectedPlant: SavedPlant?
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Image placeholder
            if let image = plantImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColorScheme.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColorScheme.primary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(plant.name)
                    .font(.headline)
                    .foregroundColor(AppColorScheme.textPrimary)
                
                if let scientific = plant.scientificName {
                    Text(scientific)
                        .font(.caption)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                Text(plant.estimatedRevenue)
                    .font(.subheadline)
                    .foregroundColor(AppColorScheme.primary)
                    .fontWeight(.medium)
                
                Text(formatDate(plant.addedAt))
                    .font(.caption)
                    .foregroundColor(AppColorScheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColorScheme.textSecondary)
        }
        .padding()
        .background(AppColorScheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColorScheme.border, lineWidth: 1)
        )
        .shadow(color: AppColorScheme.overlayLight, radius: 5, x: 0, y: 2)
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
        NavigationView {
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
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

