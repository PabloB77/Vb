//
//  ContentView.swift
//  AppTest
//
//  Created by Pablo Badra on 10/6/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if !authViewModel.isAuthenticated {
                LoginView()
            } else if !authViewModel.hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainView()
            }
        }
        .environmentObject(authViewModel)
    }
}

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingSettings = false
    @State private var isHoveringLogo = false
    @State private var selectedTab = 0
    @State private var showingMyGarden = false
    @State private var showingLearn = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Beautiful header with centered logo
            ZStack(alignment: .center) {
                // Unified gradient background
                AppColorScheme.backgroundGradient
                    .edgesIgnoringSafeArea(.top)
                
                // Subtle pattern overlay
                ZStack {
                    Circle()
                        .fill(AppColorScheme.primary.opacity(0.03))
                        .frame(width: 300, height: 300)
                        .offset(x: -150, y: -100)
                    
                    Circle()
                        .fill(AppColorScheme.accent.opacity(0.03))
                        .frame(width: 200, height: 200)
                        .offset(x: 150, y: -80)
                }
                
                VStack(spacing: 0) {
                    // Top bar with settings on right - Fixed position with padding
                    HStack {
                        Spacer()
                        
                        // Settings on the right - Fixed
                        HStack(spacing: 12) {
                            // Profile indicator
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [AppColorScheme.primary, AppColorScheme.accent]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Text(authViewModel.user?.email?.prefix(1).uppercased() ?? "U")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: AppColorScheme.overlayLight, radius: 5)
                            
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(AppColorScheme.textSecondary)
                                    .frame(width: 38, height: 38)
                                    .background(AppColorScheme.buttonSecondary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .help("Settings")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(height: 80)
                    
                    // Logo - CENTERED with fixed position
                    Image("PLANTIFY-2")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
                        .scaleEffect(isHoveringLogo ? 1.05 : 1.0)
                        .onHover { hovering in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isHoveringLogo = hovering
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                    
                    // Navigation tabs - Better spacing and fixed with padding
                    HStack(spacing: 30) {
                        TabButton(
                            title: "Explore",
                            icon: "map.fill",
                            isSelected: selectedTab == 0,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTab = 0
                                }
                            }
                        )
                        
                        TabButton(
                            title: "My Garden",
                            icon: "leaf.fill",
                            isSelected: selectedTab == 1,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTab = 1
                                    showingMyGarden = true
                                }
                            }
                        )
                        
                        TabButton(
                            title: "Learn",
                            icon: "book.fill",
                            isSelected: selectedTab == 2,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTab = 2
                                    showingLearn = true
                                }
                            }
                        )
                    }
                    .padding(.vertical, 12)
                    .padding(.bottom, 16)
                    .frame(height: 70)
                }
                
                // Subtle bottom border
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.05)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 230)
            
            // Main content area with safe area handling
            GeometryReader { geometry in
                MapView()
                    .frame(height: geometry.size.height)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showingMyGarden) {
            MyGardenView()
                .environmentObject(authViewModel)
                .frame(minWidth: 700, minHeight: 600)
        }
        .sheet(isPresented: $showingLearn) {
            LearnView()
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}

// MARK: - Tab Button Component
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? AppColorScheme.primary : AppColorScheme.textSecondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppColorScheme.primary.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColorScheme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    ContentView()
}
