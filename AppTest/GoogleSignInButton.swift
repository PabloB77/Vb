import SwiftUI
import GoogleSignIn

struct GoogleSignInButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("google_logo")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("Sign in with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColorScheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColorScheme.border, lineWidth: 1.5)
            )
            .shadow(color: AppColorScheme.overlayLight, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
