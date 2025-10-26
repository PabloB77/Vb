import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEmailAuth = false

    var body: some View {
        ZStack {
            // Unified gradient background
            AppColorScheme.backgroundGradient
                .ignoresSafeArea()
            
            // Decorative circles
            Circle()
                .fill(Color(red: 0.25, green: 0.70, blue: 0.60).opacity(0.08))
                .frame(width: 400, height: 400)
                .offset(x: -250, y: -200)
            
            Circle()
                .fill(Color(red: 0.30, green: 0.65, blue: 0.85).opacity(0.08))
                .frame(width: 300, height: 300)
                .offset(x: 250, y: 200)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Header with Logo - MUCH BIGGER
                VStack(spacing: 20) {
                    Image("PLANTIFY-2")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 10)
                }
                .padding(.bottom, 30)

                // Authentication Options - Beautiful and modern
                VStack(spacing: 18) {
                    // Google Sign In
                    GoogleSignInButton {
                        authViewModel.signInWithGoogle()
                    }
                    
                    // Email/Password Sign In
                    Button(action: {
                        showEmailAuth = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                            Text("Continue with Email")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColorScheme.buttonPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: AppColorScheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    
                    // Guest Sign In - Much more visible
                    Button(action: {
                        authViewModel.signInAsGuest()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                            Text("Continue as Guest")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColorScheme.buttonSecondary)
                        .foregroundColor(AppColorScheme.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColorScheme.border, lineWidth: 2)
                        )
                        .shadow(color: AppColorScheme.overlayLight, radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .frame(maxWidth: 600)
            
            // Loading Indicator - Overlay
            if authViewModel.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Signing in...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                }
                .padding(30)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 20)
            }
            
            // Error Message - Overlay
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
                .environmentObject(authViewModel)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
