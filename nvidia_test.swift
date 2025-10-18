#!/usr/bin/env swift
import Foundation

let apiKey = "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"
let model = "nvidia/llama-3.3-nemotron-super-49b-v1.5"
let url = URL(string: "https://integrate.api.nvidia.com/v1/chat/completions")!

class StreamingDelegate: NSObject, URLSessionDataDelegate {
    var buffer = ""
    let semaphore: DispatchSemaphore
    var error: Error?
    
    init(semaphore: DispatchSemaphore) {
        self.semaphore = semaphore
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        buffer += chunk
        
        // Process complete lines
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
                    print(content, terminator: "")
                    fflush(stdout)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.error = error
        print() // Final newline
        semaphore.signal()
    }
}

func generateNVidiaStreaming(soilData: String) -> Result<Void, Error> {
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
    - Color (estimated): [select one: Black, Brown, Red-Brown, Yellow, Gray, Mixed]
    
    
    
    
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
    
    let semaphore = DispatchSemaphore(value: 0)
    let delegate = StreamingDelegate(semaphore: semaphore)
    
    let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    let task = session.dataTask(with: request)
    task.resume()
    
    semaphore.wait()
    
    if let error = delegate.error {
        return .failure(error)
    }
    
    return .success(())
}func generateNVidiaStreaming(soilData: String) -> Result<Void, Error> {
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
    - Color (estimated): [select one: Black, Brown, Red-Brown, Yellow, Gray, Mixed]
    
    
    
    
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
    
    let semaphore = DispatchSemaphore(value: 0)
    let delegate = StreamingDelegate(semaphore: semaphore)
    
    let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    let task = session.dataTask(with: request)
    task.resume()
    
    semaphore.wait()
    
    if let error = delegate.error {
        return .failure(error)
    }
    
    return .success(())
}

let soilData = """
Soil: Orangeburg loamy sand, 6 to 10 percent slopes | Taxonomy: Fine-loamy, siliceous, thermic Typic Kandiudults | % composition: 15.1
Soil: Esto soils, 10 to 25 percent slopes | Taxonomy: Fine, kaolinitic, thermic Typic Kandiudults | % composition: 14.0
Soil: Davidson clay loam, 6 to 10 percent slopes, moderately eroded | Taxonomy: Fine, kaolinitic, thermic Rhodic Kandiudults | % composition: 10.7
Soil: Davidson loam, 2 to 6 percent slopes, moderately eroded | Taxonomy: Fine, kaolinitic, thermic Rhodic Kandiudults | % composition: 9.1
Soil: Ailey soils, 10 to 15 percent slopes | Taxonomy: Loamy, kaolinitic, thermic Arenic Kanhapludults | % composition: 8.1
Soil: Gwinnett loam, 15 to 35 percent slopes, eroded | Taxonomy: Fine, kaolinitic, thermic Rhodic Kanhapludults | % composition: 6.3
Soil: Lakeland sand, 10 to 15 percent slopes | Taxonomy: Thermic, coated Typic Quartzipsamments | % composition: 5.2
Soil: Lakeland sand, 2 to 10 percent slopes | Taxonomy: Thermic, coated Typic Quartzipsamments | % composition: 5.2
Soil: Congaree and Toccoa soils | Taxonomy: Fine-loamy, mixed, nonacid, thermic Typic Udifluvents | % composition: 2.2
"""

switch generateNVidiaStreaming(soilData: soilData) {
case .success:
    break
case .failure(let error):
    fputs("\nError: \(error.localizedDescription)\n", stderr)
    exit(2)
}