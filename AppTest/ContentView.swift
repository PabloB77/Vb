//
//  ContentView.swift
//  AppTest
//
//  Created by Pablo Badra on 10/6/25.
//

import SwiftUI

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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with globe and text
            HStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Plantify.ai")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Sign Out") {
                    authViewModel.signOut()
                }
            }
            .padding()
            .background(.background)
            
            // Map view
            MapView()
        }
    }
}

#Preview {
    ContentView()
}
