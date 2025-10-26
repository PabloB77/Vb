import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var usage: String = ""
    @State private var location: String = ""

    var body: some View {
        ZStack {
            // Unified background
            AppColorScheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Just a few questions...")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AppColorScheme.textPrimary)
                        
                        if authViewModel.isGuest {
                            Text("Help us personalize your experience")
                                .font(.subheadline)
                                .foregroundColor(AppColorScheme.textSecondary)
                        } else {
                            Text("Let's get to know you better")
                                .font(.subheadline)
                                .foregroundColor(AppColorScheme.textSecondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Usage Selection
                    VStack(spacing: 16) {
                        Text("What do you plan to use this for?")
                            .font(.headline)
                            .foregroundColor(AppColorScheme.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    usage = "Personal Gardening"
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(usage == "Personal Gardening" ? .white : AppColorScheme.primary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            usage == "Personal Gardening" ?
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ) :
                                                LinearGradient(
                                                    gradient: Gradient(colors: [AppColorScheme.primary.opacity(0.15), AppColorScheme.accent.opacity(0.15)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .cornerRadius(14)
                                    
                                    Text("Personal Gardening")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(usage == "Personal Gardening" ? .white : AppColorScheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    if usage == "Personal Gardening" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(20)
                                .background(
                                    usage == "Personal Gardening" ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.25, green: 0.70, blue: 0.60),
                                                Color(red: 0.20, green: 0.60, blue: 0.50)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [AppColorScheme.cardBackground]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            usage == "Personal Gardening" ?
                                                Color.clear :
                                                AppColorScheme.border,
                                            lineWidth: 1.5
                                        )
                                )
                                .cornerRadius(16)
                                .shadow(
                                    color: usage == "Personal Gardening" ?
                                        AppColorScheme.primary.opacity(0.3) :
                                        Color.clear,
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    usage = "Farming"
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "tractor.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(usage == "Farming" ? .white : AppColorScheme.primary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            usage == "Farming" ?
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ) :
                                                LinearGradient(
                                                    gradient: Gradient(colors: [AppColorScheme.primary.opacity(0.15), AppColorScheme.accent.opacity(0.15)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .cornerRadius(14)
                                    
                                    Text("Farming")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(usage == "Farming" ? .white : AppColorScheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    if usage == "Farming" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(20)
                                .background(
                                    usage == "Farming" ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.25, green: 0.70, blue: 0.60),
                                                Color(red: 0.20, green: 0.60, blue: 0.50)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [AppColorScheme.cardBackground]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            usage == "Farming" ?
                                                Color.clear :
                                                AppColorScheme.border,
                                            lineWidth: 1.5
                                        )
                                )
                                .cornerRadius(16)
                                .shadow(
                                    color: usage == "Farming" ?
                                        AppColorScheme.primary.opacity(0.3) :
                                        Color.clear,
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Location Input
                    VStack(spacing: 16) {
                        Text("Enter your State, Address, or Zip Code")
                            .font(.headline)
                            .foregroundColor(AppColorScheme.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        TextField("Location", text: $location)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColorScheme.cardBackground)
                            .foregroundColor(AppColorScheme.textPrimary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColorScheme.border, lineWidth: 1.5)
                            )
                            .shadow(color: AppColorScheme.overlayLight, radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    
                    // Guest User Notice
                    if authViewModel.isGuest {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppColorScheme.accent)
                                Text("Guest Account")
                                    .fontWeight(.medium)
                                    .foregroundColor(AppColorScheme.textPrimary)
                            }
                            Text("You can always create an account later to save your data permanently")
                                .font(.caption)
                                .foregroundColor(AppColorScheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(AppColorScheme.accent.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Save Button
                    Button(action: {
                        authViewModel.saveOnboardingData(usage: usage, location: location)
                    }) {
                        HStack(spacing: 12) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                            }
                            Text("Continue")
                                .fontWeight(.semibold)
                                .font(.system(size: 16))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            canSave ?
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.25, green: 0.70, blue: 0.60),
                                        Color(red: 0.20, green: 0.60, blue: 0.50)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    gradient: Gradient(colors: [AppColorScheme.buttonSecondary]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .foregroundColor(canSave ? .white : AppColorScheme.textSecondary)
                        .cornerRadius(14)
                        .shadow(
                            color: canSave ? AppColorScheme.primary.opacity(0.3) : Color.clear,
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    }
                    .disabled(!canSave || authViewModel.isLoading)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private var canSave: Bool {
        return !usage.isEmpty && !location.isEmpty
    }
}
