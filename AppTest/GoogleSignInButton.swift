import SwiftUI
import GoogleSignIn

struct GoogleSignInButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image("google_logo") // Make sure to add a "google_logo" image to your assets
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("Sign in with Google")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
        }
    }
}
