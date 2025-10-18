import GoogleGenerativeAI
import SwiftUI

public class AIManager {
    static let model = GenerativeModel(name: "gemini-2.5-pro", apiKey: "AIzaSyDERalkr9wDg5Ux5e3CQ8qFk_5bj19EKLk")

    public static func generateGemini(prompt: String) {
        let model = GenerativeModel(name: "gemini-2.5-pro", apiKey: "AIzaSyDERalkr9wDg5Ux5e3CQ8qFk_5bj19EKLk")
        Task{
            do {
                let response = try await model.generateContent(prompt)
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

    // NEW: Live streaming version with chunk callback
    public static func generateNVidiaStreamingLiveGenericThink(
        soilData: String,
        onChunk: @escaping (String) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let apiKey = "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"
        let model = "nvidia/llama-3.3-nemotron-super-49b-v1.5"
        let url = URL(string: "https://integrate.api.nvidia.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        \(soilData)
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0,
            "top_p": 1,
            "max_tokens": 2048,
            "frequency_penalty": 0,
            "presence_penalty": 0,
            "stream": true
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let delegate = LiveStreamingDelegate(onChunk: onChunk, completion: completion)
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }
    public static func generateNVidiaStreamingLiveGeneric(
        soilData: String,
        onChunk: @escaping (String) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let apiKey = "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"
        let model = "nvidia/llama-3.3-nemotron-super-49b-v1.5"
        let url = URL(string: "https://integrate.api.nvidia.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        \(soilData)
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "/no_think"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0,
            "top_p": 1,
            "max_tokens": 2048,
            "frequency_penalty": 0,
            "presence_penalty": 0,
            "stream": true
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let delegate = LiveStreamingDelegate(onChunk: onChunk, completion: completion)
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }

       public static func generateNVidiaStreamingLive(
        soilData: String,
        onChunk: @escaping (String) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let apiKey = "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"
        let model = "nvidia/llama-3.3-nemotron-super-49b-v1.5"
        let url = URL(string: "https://integrate.api.nvidia.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        TASK:
        - Determine the combined overall soil characteristics for the area based on the given data.
        
        \(soilData)
        
        
        
        
        OUTPUT FORMAT (strict - only provide the selected values):
        - Porosity: [select one: Virtually none, Low, Medium Low, Medium, Medium High, High]
        - Organic Matter: [select one: Very Low, Low, Medium Low, Medium, Medium High, High]  
        - Soil Texture: [select one: Sand, Sand and Loam, Loam, Loam and Clay, Clay, Clay and Loam, Sand and Clay]
        - pH (estimated): [select one: 4.5-6, 6-7, 7-8.5]
        - Drainage: [select one: Poor, Moderate, Well-drained, Excessive]
        - Color (estimated): [select one: Yellow, Sand, Black, Brown, Red, Red-Brown, Gray, Mixed]
        
        
        
        
        RULES:
        - Base the result on the dominant soils by percentage.
        - Minor soils (under ~5%) may be excluded.
        - Choose only one value per category.
        - No explanations or commentary.
        - No headings or extra lines.
        - Output must contain exactly six lines matching the format above.
        - ONLY choose from output values offered
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "/no_think"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0,
            "top_p": 1,
            "max_tokens": 2048,
            "frequency_penalty": 0,
            "presence_penalty": 0,
            "stream": true
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let delegate = LiveStreamingDelegate(onChunk: onChunk, completion: completion)
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }

    // Original version that returns full output at end
    public static func generateNVidiaStreaming(soilData: String, completion: @escaping (Result<String, Error>) -> Void) {
        let apiKey = "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"
        let model = "nvidia/llama-3.3-nemotron-super-49b-v1.5"
        let url = URL(string: "https://integrate.api.nvidia.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        TASK:
        - Determine the combined overall soil characteristics for the area based on the given data.
        
        \(soilData)
        
        
        
        
        OUTPUT FORMAT (strict - only provide the selected values):
        - Porosity: [select one: Virtually none, Low, Medium Low, Medium, Medium High, High]
        - Organic Matter: [select one: Very Low, Low, Medium Low, Medium, Medium High, High]  
        - Soil Texture: [select one: Sand, Sand and Loam, Loam, Loam and Clay, Clay, Clay and Loam, Sand and Clay]
        - pH (estimated): [select one: 4.5-6, 6-7, 7-8.5]
        - Drainage: [select one: Poor, Moderate, Well-drained, Excessive]
        - Color (estimated): [select one: Yellow, Sand, Black, Brown, Red, Red-Brown, Gray, Mixed]
        
        
        
        
        RULES:
        - Base the result on the dominant soils by percentage.
        - Minor soils (under ~5%) may be excluded.
        - Choose only one value per category.
        - No explanations or commentary.
        - No headings or extra lines.
        - Output must contain exactly six lines matching the format above.
        - ONLY choose from output values offered
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "/no_think"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0,
            "top_p": 1,
            "max_tokens": 2048,
            "frequency_penalty": 0,
            "presence_penalty": 0,
            "stream": true
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let delegate = StreamingDelegate(completion: completion)
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
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
    }
}


// NEW: Live streaming delegate that calls onChunk for each piece
class LiveStreamingDelegate: NSObject, URLSessionDataDelegate {
    var buffer = ""
    let onChunk: (String) -> Void
    let completion: (Result<Void, Error>) -> Void
    
    init(onChunk: @escaping (String) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        self.onChunk = onChunk
        self.completion = completion
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        buffer += chunk
        
        let lines = buffer.components(separatedBy: "\n")
        buffer = lines.last ?? ""
        
        for line in lines.dropLast() {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                
                if jsonString == "[DONE]" {
                    continue
                }
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let delta = first["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    onChunk(content)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(()))
        }
    }
}


// Original streaming delegate
class StreamingDelegate: NSObject, URLSessionDataDelegate {
    var buffer = ""
    var fullOutput = ""
    let completion: (Result<String, Error>) -> Void
    
    init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        buffer += chunk
        
        let lines = buffer.components(separatedBy: "\n")
        buffer = lines.last ?? ""
        
        for line in lines.dropLast() {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                
                if jsonString == "[DONE]" {
                    continue
                }
                
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let delta = first["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    fullOutput += content
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(fullOutput))
        }
    }
}
