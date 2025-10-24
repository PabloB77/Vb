import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var usage: String = ""
    @State private var location: String = ""

    var body: some View {
        VStack {
            Text("Just a few questions...")
                .font(.largeTitle)
                .padding()

            Text("What do you plan to use this for?")
            HStack {
                Button("Personal Gardening") {
                    usage = "Personal Gardening"
                }
                .padding()
                .background(usage == "Personal Gardening" ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Farming") {
                    usage = "Farming"
                }
                .padding()
                .background(usage == "Farming" ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()

            Text("Enter your State, Address, or Zip Code")
            TextField("Location", text: $location)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save") {
                authViewModel.saveOnboardingData(usage: usage, location: location)
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}
