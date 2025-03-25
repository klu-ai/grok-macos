//
//  Run.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/19/25.
//
//  Description:
//  Manages API-based model inference for the Grok assistant.
//  Handles API requests, response processing, and error handling.
//
//  Key features:
//  - API request management
//  - Response streaming
//  - Error handling
//  - State management
//
//  Dependencies:
//  - Foundation: Core functionality
//  - SwiftUI: UI framework
//
//  Usage:
//  - Initialize with API configuration
//  - Send requests to model API
//  - Process streaming responses
//  - Handle errors and state changes

import Foundation
import SwiftUI

/// Errors that can occur during model inference
enum RunLLMError: Error {
    case apiError(String)
    case networkError(String)
    case authenticationError(String)
}

/// Manages API-based model inference
@MainActor
class RunLLM: ObservableObject {
    /// Whether a request is currently running
    @Published var running: Bool = false
    
    /// Whether the current request has been cancelled
    @Published var cancelled: Bool = false
    
    /// The current output from the model
    @Published var output: String = ""
    
    /// The current status message
    @Published var stat: String = ""
    
    /// The current progress (0.0 to 1.0)
    @Published var progress: Double = 0.0
    
    /// Time spent thinking/processing
    @Published var thinkingTime: TimeInterval = 0
    
    /// Whether the model is currently thinking
    @Published var isThinking: Bool = false
    
    /// The current generation task
    private var generationTask: Task<String, Error>?
    
    /// API configuration
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "apiKey") ?? ""
    }
    
    private var apiEndpoint: String {
        UserDefaults.standard.string(forKey: "apiEndpoint") ?? "https://api.example.com"
    }
    
    /// Generates a response using the API
    /// - Parameters:
    ///   - messages: The conversation history
    ///   - systemPrompt: The system-level prompt
    /// - Returns: The generated response
    /// - Throws: RunLLMError if the request fails
    func generate(messages: [[String: String]], systemPrompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw RunLLMError.authenticationError("API key not configured")
        }
        
        guard let url = URL(string: apiEndpoint) else {
            throw RunLLMError.networkError("Invalid API endpoint")
        }
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare the request body
        let requestBody: [String: Any] = [
            "model": UserDefaults.standard.string(forKey: "selectedModel") ?? "grok-3",
            "messages": messages,
            "temperature": UserDefaults.standard.double(forKey: "temperature"),
            "max_tokens": UserDefaults.standard.integer(forKey: "maxTokens"),
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Start the request
        running = true
        isThinking = true
        let startTime = Date()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RunLLMError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode == 401 {
                throw RunLLMError.authenticationError("Invalid API key")
            }
            
            if httpResponse.statusCode != 200 {
                throw RunLLMError.apiError("API request failed with status code \(httpResponse.statusCode)")
            }
            
            guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = responseDict["content"] as? String else {
                throw RunLLMError.apiError("Invalid response format")
            }
            
            thinkingTime = Date().timeIntervalSince(startTime)
            isThinking = false
            running = false
            
            return content
            
        } catch {
            running = false
            isThinking = false
            throw RunLLMError.networkError(error.localizedDescription)
        }
    }
    
    /// Stops the current generation task
    func stop() {
        generationTask?.cancel()
        cancelled = true
        running = false
        isThinking = false
    }
}
