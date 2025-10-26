//
//  AppTestApp.swift
//  AppTest
//
//  Created by Pablo Badra on 10/6/25.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct AppTestApp: App {
    
    init() {
        // Configure Firebase with error handling
        do {
            FirebaseApp.configure()
        } catch {
            print("Firebase configuration error: \(error)")
            // Try to clear cache and reconfigure
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                FirebaseApp.configure()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 800)
    }
}
