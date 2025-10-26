import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileHeaderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Picture Placeholder
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: authViewModel.isGuest ? "person.circle" : "person.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authViewModel.isGuest ? "Guest User" : getUserDisplayName())
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(authViewModel.isGuest ? "Tap to create account" : getUserEmail())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !authViewModel.userUsage.isEmpty {
                    Text(authViewModel.userUsage)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
    
    private func getUserDisplayName() -> String {
        // Get user's display name from Firebase Auth
        if let user = Auth.auth().currentUser {
            return user.displayName ?? "User"
        }
        return "User"
    }
    
    private func getUserEmail() -> String {
        if let user = Auth.auth().currentUser {
            return user.email ?? "No email"
        }
        return "No email"
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColorScheme.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColorScheme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColorScheme.textSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovered ? AppColorScheme.primary.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAccount = false
    @State private var showingEditProfile = false
    @State private var showingChangePassword = false
    @State private var showingSignOutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Section
                    profileSection
                    
                    // Account Settings
                    accountSection
                    
                    // App Settings
                    preferencesSection
                    
                    // Support Section
                    supportSection
                    
                    // Danger Zone
                    accountActionsSection
                }
                .padding()
            }
            .frame(width: 700, height: 600)
            .fixedSize()
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .foregroundColor(AppColorScheme.primary)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authViewModel)
                .frame(width: 1000, height: 800)
                .fixedSize()
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView()
                .environmentObject(authViewModel)
        }
        .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement account deletion
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
    
    // MARK: - Section Components
    
    private var profileSection: some View {
        VStack(spacing: 16) {
            Text("Profile")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ProfileHeaderView()
                .onTapGesture {
                    showingEditProfile = true
                }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var accountSection: some View {
        VStack(spacing: 16) {
            Text("Account")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "person.circle",
                    title: "Edit Profile",
                    subtitle: "Update your personal information"
                ) {
                    showingEditProfile = true
                }
                
                if !authViewModel.isGuest {
                    SettingsRow(
                        icon: "key",
                        title: "Change Password",
                        subtitle: "Update your password"
                    ) {
                        showingChangePassword = true
                    }
                }
                
                SettingsRow(
                    icon: "location",
                    title: "Usage Preference",
                    subtitle: authViewModel.userUsage.isEmpty ? "Tap to set" : authViewModel.userUsage
                ) {
                    showingEditProfile = true
                }
                
                SettingsRow(
                    icon: "map",
                    title: "Location",
                    subtitle: "Tap to edit"
                ) {
                    showingEditProfile = true
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var preferencesSection: some View {
        VStack(spacing: 16) {
            Text("Preferences")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "bell",
                    title: "Notifications",
                    subtitle: "Manage your notifications"
                ) {
                    // Notification settings
                }
                
                SettingsRow(
                    icon: "paintbrush",
                    title: "Appearance",
                    subtitle: "Dark mode settings"
                ) {
                    // Appearance settings
                }
                
                SettingsRow(
                    icon: "globe",
                    title: "Language",
                    subtitle: "English"
                ) {
                    // Language settings
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var supportSection: some View {
        VStack(spacing: 16) {
            Text("Support")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    subtitle: "Get help with the app"
                ) {
                    // Help section
                }
                
                SettingsRow(
                    icon: "doc.text",
                    title: "Privacy Policy",
                    subtitle: "Read our privacy policy"
                ) {
                    // Privacy policy
                }
                
                SettingsRow(
                    icon: "doc.plaintext",
                    title: "Terms of Service",
                    subtitle: "Read our terms"
                ) {
                    // Terms of service
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var accountActionsSection: some View {
        VStack(spacing: 16) {
            Text("Account Actions")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                if authViewModel.isGuest {
                    Button(action: {
                        // Convert guest to regular account
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)
                            Text("Create Account")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    showingSignOutConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.orange)
                        Text("Sign Out")
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                if !authViewModel.isGuest {
                    Button(action: {
                        showingDeleteAccount = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete Account")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(16)
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var email = ""
    @State private var usage = ""
    @State private var location = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    personalInformationSection
                    usagePreferenceSection
                    locationSection
                    messageSection
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    // MARK: - View Components
    
    private var personalInformationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Personal Information")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                displayNameField
                emailField
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var displayNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display Name")
                .font(.headline)
            TextField("Enter your display name", text: $displayName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(height: 44)
        }
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.headline)
            TextField("Enter your email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(height: 44)
        }
    }
    
    private var usagePreferenceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What do you plan to use this for?")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                gardeningButton
                farmingButton
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var gardeningButton: some View {
        Button(action: {
            usage = "Personal Gardening"
        }) {
            HStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Gardening")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Growing vegetables, herbs, and flowers at home")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if usage == "Personal Gardening" {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(20)
            .background(usage == "Personal Gardening" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .foregroundColor(usage == "Personal Gardening" ? .blue : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(usage == "Personal Gardening" ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var farmingButton: some View {
        Button(action: {
            usage = "Farming"
        }) {
            HStack(spacing: 16) {
                Image(systemName: "tractor.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Farming")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Commercial agriculture and large-scale growing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if usage == "Farming" {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(20)
            .background(usage == "Farming" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .foregroundColor(usage == "Farming" ? .blue : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(usage == "Farming" ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Location")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("State, Address, or Zip Code")
                    .font(.headline)
                TextField("Enter your location", text: $location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 44)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var messageSection: some View {
        VStack(spacing: 16) {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
            
            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
    
    private func loadCurrentProfile() {
        if let user = Auth.auth().currentUser {
            displayName = user.displayName ?? ""
            email = user.email ?? ""
            usage = authViewModel.userUsage
            // Load location from Firestore if available
            loadLocationFromFirestore()
        }
    }
    
    private func loadLocationFromFirestore() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { (document, error) in
            if let document = document, document.exists {
                if let locationData = document.data()?["location"] as? String {
                    DispatchQueue.main.async {
                        self.location = locationData
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Update display name
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = displayName
        changeRequest?.commitChanges { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                } else {
                    // Save usage and location to Firestore
                    self.saveToFirestore()
                }
            }
        }
    }
    
    private func saveToFirestore() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        var userData: [String: Any] = [
            "usage": usage,
            "location": location,
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Add email if not a guest user
        if !user.isAnonymous {
            userData["email"] = email
        }
        
        db.collection("users").document(user.uid).setData(userData, merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.successMessage = "Profile updated successfully!"
                    // Update the auth view model
                    self.authViewModel.userUsage = self.usage
                }
                self.isLoading = false
            }
        }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                } header: {
                    Text("Password Change")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let successMessage = successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Change Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Change") {
                        changePassword()
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !currentPassword.isEmpty && 
               !newPassword.isEmpty && 
               !confirmPassword.isEmpty &&
               newPassword == confirmPassword &&
               newPassword.count >= 6
    }
    
    private func changePassword() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.successMessage = "Password changed successfully!"
                    // Clear form
                    self.currentPassword = ""
                    self.newPassword = ""
                    self.confirmPassword = ""
                }
                self.isLoading = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}

