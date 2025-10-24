import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to Plantify.ai")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            Text("Please sign in to continue")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)

            GoogleSignInButton {
                authViewModel.signInWithGoogle()
            }
            Spacer()
        }
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
