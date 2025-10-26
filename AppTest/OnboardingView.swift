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
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                usage = "Personal Gardening"
                            }) {
                                HStack {
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(AppColorScheme.primary)
                                    Text("Personal Gardening")
                                        .fontWeight(.medium)
                                    Spacer()
                                    if usage == "Personal Gardening" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColorScheme.primary)
                                    }
                                }
                                .padding()
                                .background(usage == "Personal Gardening" ? AppColorScheme.primary.opacity(0.1) : AppColorScheme.buttonSecondary)
                                .foregroundColor(usage == "Personal Gardening" ? AppColorScheme.primary : AppColorScheme.textPrimary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(usage == "Personal Gardening" ? AppColorScheme.primary : Color.clear, lineWidth: 2)
                                )
                            }
                            
                            Button(action: {
                                usage = "Farming"
                            }) {
                                HStack {
                                    Image(systemName: "tractor.fill")
                                        .foregroundColor(AppColorScheme.primary)
                                    Text("Farming")
                                        .fontWeight(.medium)
                                    Spacer()
                                    if usage == "Farming" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColorScheme.primary)
                                    }
                                }
                                .padding()
                                .background(usage == "Farming" ? AppColorScheme.primary.opacity(0.1) : AppColorScheme.buttonSecondary)
                                .foregroundColor(usage == "Farming" ? AppColorScheme.primary : AppColorScheme.textPrimary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(usage == "Farming" ? AppColorScheme.primary : Color.clear, lineWidth: 2)
                                )
                            }
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
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color(red: 0.25, green: 0.70, blue: 0.60) : AppColorScheme.buttonSecondary)
                        .foregroundColor(canSave ? .white : AppColorScheme.textSecondary)
                        .cornerRadius(12)
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
