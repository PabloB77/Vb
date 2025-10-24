import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import Combine
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        checkAuthentication()
    }

    func checkAuthentication() {
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            self.isAuthenticated = user != nil
            if let user = user {
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).getDocument { (document, error) in
                    if let document = document, document.exists {
                        self.hasCompletedOnboarding = true
                    } else {
                        self.hasCompletedOnboarding = false
                    }
                }
            }
        }
    }

    @MainActor
    func signInWithGoogle() {
        Task {
            do {
                guard let clientID = FirebaseApp.app()?.options.clientID else { return }
                let config = GIDConfiguration(clientID: clientID)
                GIDSignIn.sharedInstance.configuration = config

                #if os(iOS)
                guard let window = UIApplication.shared.connectedScenes.flatMap({ ($0 as? UIWindowScene)?.windows ?? [] }).first else { return }
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window.rootViewController!)
                #elseif os(macOS)
                guard let window = NSApplication.shared.windows.first else { return }
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
                #endif
                
                handleSignIn(user: result.user)

            } catch {
                print("Google Sign In error: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleSignIn(user: GIDGoogleUser) {
        guard let idToken = user.idToken?.tokenString else {
            print("ID token not found")
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)

        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print("Firebase Sign In error: \(error.localizedDescription)")
                return
            }
            self.isAuthenticated = true
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            isAuthenticated = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    func saveOnboardingData(usage: String, location: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "usage": usage,
            "location": location
        ]) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                self.hasCompletedOnboarding = true
            }
        }
    }
}
