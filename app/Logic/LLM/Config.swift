//
//  Config.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/19/25.
//
//  Description:
//  This file provides configuration types and utilities for API-based model inference.
//  It defines model types and adds utility functions for constructing prompt histories
//  and managing model configurations.
//
//  Usage:
//  - Import this file to access model configuration utilities
//  - Use getPromptHistory(thread:systemPrompt:) to build a prompt history array
//  - Access predefined configurations via the provided static properties
//
//  Dependencies:
//  - Foundation: Core functionality

import Foundation

/// Configuration for API-based model inference
public struct ModelConfiguration {
    /// The name of the model to use for API requests
    public let name: String
    
    /// The type of model (text, vision, etc.)
    public let type: ModelType
    
    /// The model's capabilities and parameters
    public let parameters: [String: Any]
    
    /// Enumeration for distinguishing between different model types
    public enum ModelType: String {
        case text
        case vision
        case audio
        case embedding
    }
    
    /// Constructs the prompt history for a given conversation thread
    /// - Parameters:
    ///   - thread: The conversation thread containing sorted messages
    ///   - systemPrompt: The system-level prompt to set the conversation context
    /// - Returns: An array of dictionaries, each representing a message with a "role" and "content"
    func getPromptHistory(thread: Thread, systemPrompt: String) -> [[String: String]] {
        var history: [[String: String]] = []
        
        // Append the system prompt as the initial context
        history.append([
            "role": "system",
            "content": systemPrompt,
        ])
        
        // Append each message from the thread
        for message in thread.sortedMessages {
            history.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        return history
    }
    
    /// The default model configuration used by the system
    public static var defaultModel: ModelConfiguration {
        ModelConfiguration(
            name: "grok-3",
            type: .text,
            parameters: [
                "temperature": 0.7,
                "max_tokens": 4096
            ]
        )
    }
    
    /// Gets a model configuration by name
    /// - Parameter name: The name of the model to retrieve
    /// - Returns: The corresponding ModelConfiguration if found, nil otherwise
    public static func getModelByName(_ name: String) -> ModelConfiguration? {
        // In a real implementation, this would fetch model configurations from a service
        // For now, return a default configuration
        return ModelConfiguration(
            name: name,
            type: .text,
            parameters: [
                "temperature": 0.7,
                "max_tokens": 4096
            ]
        )
    }
    
    /// Formats a message string for proper tokenization
    /// - Parameter message: The original message string
    /// - Returns: The formatted message string
    func formatForTokenizer(_ message: String) -> String {
        return message
            .replacingOccurrences(of: "<think>", with: "")
            .replacingOccurrences(of: "</think>", with: "")
    }
}

// MARK: - Equatable Conformance
extension ModelConfiguration: Equatable {
    /// Compares two model configurations based on their names.
    ///
    /// - Parameters:
    ///   - lhs: The first model configuration.
    ///   - rhs: The second model configuration.
    /// - Returns: `true` if both configurations have the same name; otherwise, `false`.
    public static func == (lhs: ModelConfiguration, rhs: ModelConfiguration) -> Bool {
        return lhs.name == rhs.name
    }
}
