import GoogleGenerativeAI
import SwiftUI

public class AIManager {
    static let model = GenerativeModel(name: "gemini-2.5-pro", apiKey: "AIzaSyDERalkr9wDg5Ux5e3CQ8qFk_5bj19EKLk")


    public static func generateGemini() {
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

    public static func generateNVidia1(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
    let apiKey = "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"
    let model = "nvidia/llama-3.3-nemotron-super-49b-v1.5"
    let url = URL(string: "https://integrate.api.nvidia.com/v1/chat/completions")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let body: [String: Any] = [
        "model": model,
        "messages": [
            ["role": "user", "content": prompt]
        ],
        "temperature": 0.6,
        "top_p": 0.95,
        "max_tokens": 65536,
        "frequency_penalty": 0,
        "presence_penalty": 0,
        "stream": false
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1, userInfo: nil)))
            return
        }
        
        // Debug output
        if let rawString = String(data: data, encoding: .utf8) {
            print("Raw API Response: \(rawString)")
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            if let jsonDict = json as? [String: Any],
               let choices = jsonDict["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(.success(content))
            } else {
                completion(.failure(NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not parse response"])))
            }
        } catch {
            completion(.failure(error))
        }
    }.resume()
}}
