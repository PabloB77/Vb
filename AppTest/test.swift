import GoogleGenerativeAI
import SwiftUI

public class AIManager {
    static let model = GenerativeModel(name: "gemini-2.5-pro", apiKey: "AIzaSyDERalkr9wDg5Ux5e3CQ8qFk_5bj19EKLk")


    public static func generate() {
        let model = GenerativeModel(name: "gemini-2.5-pro", apiKey: "AIzaSyDERalkr9wDg5Ux5e3CQ8qFk_5bj19EKLk")
        Task{
            do {
                let response = try await model.generateContent("Why is grass green? Limit response to 4 sentences")
                if let text = response.text{
                    print (text)
                    return text
                } else {
                    return "Empty"
                }
            } catch {
                print("Error generating content: \(error)")
                return "Error"
            }
        }
    }
}
