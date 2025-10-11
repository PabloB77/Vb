//
//  ContentView.swift
//  AppTest
//
//  Created by Pablo Badra on 10/6/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header with globe and text
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Plantify.ai")
                    .font(.title2)
                    .fontWeight(.semibold)
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
