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
    @Published var isGuest: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var userUsage: String = "" // Store user's usage preference (gardening/farming)
    @Published var user: User? = nil // Store the current user
    private var cancellables = Set<AnyCancellable>()

    init() {
        checkAuthentication()
    }

    func checkAuthentication() {
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            self.user = user
            self.isAuthenticated = user != nil
            if let user = user {
                // Check if this is a guest user (anonymous)
                self.isGuest = user.isAnonymous
                
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).getDocument { (document, error) in
                    if let document = document, document.exists {
                        self.hasCompletedOnboarding = true
                        // Load user's usage preference
                        if let usage = document.data()?["usage"] as? String {
                            self.userUsage = usage
                        }
                    } else {
                        self.hasCompletedOnboarding = false
                        self.userUsage = ""
                    }
                }
            } else {
                self.isGuest = false
                self.hasCompletedOnboarding = false
                self.userUsage = ""
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

    // MARK: - Email/Password Authentication
    
    @MainActor
    func signInWithEmail(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isAuthenticated = true
                    self?.isGuest = false
                }
            }
        }
    }
    
    @MainActor
    func signUpWithEmail(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isAuthenticated = true
                    self?.isGuest = false
                }
            }
        }
    }
    
    // MARK: - Guest Authentication
    
    @MainActor
    func signInAsGuest() {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isAuthenticated = true
                    self?.isGuest = true
                }
            }
        }
    }
    
    // MARK: - Password Reset
    
    @MainActor
    func resetPassword(email: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] (error) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.errorMessage = "Password reset email sent!"
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            isAuthenticated = false
            isGuest = false
            hasCompletedOnboarding = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    func saveOnboardingData(usage: String, location: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        var userData: [String: Any] = [
            "usage": usage,
            "location": location,
            "isGuest": user.isAnonymous,
            "createdAt": Timestamp(date: Date())
        ]
        
        // Add email if not a guest user
        if !user.isAnonymous, let email = user.email {
            userData["email"] = email
        }
        
        db.collection("users").document(user.uid).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                self.hasCompletedOnboarding = true
            }
        }
    }
}
