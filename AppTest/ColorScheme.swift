import SwiftUI

// MARK: - Unified Color Scheme
struct AppColorScheme {
    // Primary Colors - Professional Teal-Green
    static let primary = Color(red: 0.20, green: 0.60, blue: 0.50) // Teal-green
    static let primaryLight = Color(red: 0.25, green: 0.70, blue: 0.60)
    static let primaryDark = Color(red: 0.15, green: 0.50, blue: 0.40)
    
    // Accent Colors
    static let accent = Color(red: 0.30, green: 0.65, blue: 0.85) // Soft blue
    static let accentLight = Color(red: 0.40, green: 0.75, blue: 0.95)
    
    // Background Colors
    static let background = Color(red: 0.98, green: 1.0, blue: 0.98) // Soft mint-white
    static let secondaryBackground = Color(red: 0.95, green: 0.97, blue: 0.95)
    static let cardBackground = Color(red: 0.99, green: 1.0, blue: 0.99)
    
    // Text Colors
    static let textPrimary = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let textSecondary = Color(red: 0.50, green: 0.50, blue: 0.50)
    
    // Border Colors
    static let border = Color(red: 0.85, green: 0.90, blue: 0.85)
    static let borderLight = Color(red: 0.92, green: 0.95, blue: 0.92)
    
    // Success, Warning, Error
    static let success = Color(red: 0.25, green: 0.65, blue: 0.45)
    static let warning = Color(red: 0.95, green: 0.75, blue: 0.30)
    static let error = Color(red: 0.90, green: 0.30, blue: 0.35)
    
    // Overlay Colors
    static let overlayLight = Color.black.opacity(0.05)
    static let overlayMedium = Color.black.opacity(0.1)
    
    // Button Colors
    static let buttonPrimary = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.25, green: 0.70, blue: 0.60),
            Color(red: 0.20, green: 0.60, blue: 0.50)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let buttonSecondary = Color(red: 0.92, green: 0.94, blue: 0.92)
    
    // Gradient Background
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.98, green: 1.0, blue: 0.98),
            Color(red: 0.95, green: 0.97, blue: 0.95)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}

