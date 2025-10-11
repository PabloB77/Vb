//
//  AppTestApp.swift
//  AppTest
//
//  Created by Pablo Badra on 10/6/25.
//

import SwiftUI

@main
struct AppTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 800)
    }
}
