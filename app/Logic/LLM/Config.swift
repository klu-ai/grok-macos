//
//  Config.swift
//  MLX model configuration extensions
//
//  Created by Stephen M. Walker II on 2/19/25.
//
//  Description:
//  This file provides extensions to the ModelConfiguration type for LLM inference functionality.
//  It defines model types (regular vs reasoning) and adds utility functions for constructing
//  prompt histories and formatting messages for tokenization. It also supplies predefined model
//  configurations and retroactive Equatable conformance for comparing configurations by name.
//  These utilities support proper formatting and processing of LLM prompts and responses.
//
//  Usage:
//  - Import this file to access LLM inference utilities.
//  - Use getPromptHistory(thread:systemPrompt:) to build a prompt history array for LLM input.
//  - Use formatForTokenizer(_:) to format messages appropriately for tokenization.
//  - Access predefined configurations and model size information via the provided static properties.
//
//  Dependencies:
//  - Foundation: Provides core functionality.
//  - MLXLMCommon: Supplies shared definitions and types for LLM model configuration and inference.

import Foundation
import MLXLMCommon
import Models

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
}

// MARK: - Model Configuration Extensions for LLM Inference
public extension ModelConfiguration {
    /// Enumeration for distinguishing between regular and reasoning LLM model types.
    enum ModelType {
        case regular, reasoning, vision
    }

    /// Determines the type of the model based on its configuration.
    ///
    /// - Returns: `.reasoning` for reasoning models, `.vision` for vision models, otherwise `.regular`.
    var modelType: ModelType {
        if Self.reasoningModels.contains(where: { $0.name == self.name }) {
            return .reasoning
        } else if Self.visionModels.contains(where: { $0.name == self.name }) {
            return .vision
        } else {
            return .regular
        }
    }
    
    /// Extracts the repository ID string from the model configuration.
    /// - Returns: The repository ID string used for downloading the model.
    var repoId: String {
        get async {
            switch id {
            case .id(let modelId):
                return "huggingface.co/\(modelId)" // Prepend huggingface.co/ to mlx value
            case .directory:
                // This should never happen for our predefined models, but we need to handle it
                fatalError("Directory-based identifiers not supported for downloads")
            }
        }
    }
}

// MARK: - Equatable Conformance and Predefined Model Configurations
extension ModelConfiguration: @retroactive Equatable {
    /// Creates a ModelConfiguration from a Model instance.
    public static func configurationFromModel(_ model: Model) -> ModelConfiguration {
        return ModelConfiguration(id: model.mlx)
    }

    /// Compares two model configurations based on their names.
    ///
    /// - Parameters:
    ///   - lhs: The first model configuration.
    ///   - rhs: The second model configuration.
    /// - Returns: `true` if both configurations have the same name; otherwise, `false`.
    public static func == (lhs: MLXLMCommon.ModelConfiguration, rhs: MLXLMCommon.ModelConfiguration) -> Bool {
        return lhs.name == rhs.name
    }

    /// Array of core language model configurations.
    public static let coreModels: [ModelConfiguration] = CoreModels.available.map { configurationFromModel($0) }

    /// Array of reasoning model configurations.
    public static let reasoningModels: [ModelConfiguration] = ReasoningModels.available.map { configurationFromModel($0) }

    /// Array of vision model configurations.
    public static let visionModels: [ModelConfiguration] = VisionModels.available.map { configurationFromModel($0) }

    /// Array of audio model configurations.
    public static let audioModels: [ModelConfiguration] = AudioModels.available.map { configurationFromModel($0) }

    /// Array of embedding model configurations.
    public static let embeddingModels: [ModelConfiguration] = EmbeddingModels.available.map { configurationFromModel($0) }

    /// An array containing all available model configurations.
    public static var availableModels: [ModelConfiguration] = {
        return coreModels + reasoningModels + visionModels + audioModels + embeddingModels
    }()

    /// The default model configuration used by the system.
    public static var defaultModel: ModelConfiguration {
        coreModels.first!
    }
    /// Retrieves a model configuration based on the provided model name.
    ///
    /// - Parameter name: The name of the model.
    /// - Returns: The corresponding `ModelConfiguration` if it exists; otherwise, `nil`.
    public static func getModelByName(_ name: String) -> ModelConfiguration? {
        let allModels = CoreModels.available + ReasoningModels.available + VisionModels.available + AudioModels.available + EmbeddingModels.available
        if let model = allModels.first(where: { $0.name == name }) {
            return configurationFromModel(model)
        } else {
            return nil
        }
    }

    /// Formats a message string for proper tokenization.
    ///
    /// Removes any "<think>" and "</think>" tags and prepends a space if the model requires reasoning formatting.
    ///
    /// - Parameter message: The original message string.
    /// - Returns: The formatted message string suitable for the tokenizer.
    // TODO: Remove this function when Jinja gets updated
    func formatForTokenizer(_ message: String) -> String {
        if self.modelType == .reasoning || self.modelType == .regular {
            return " " + message
                .replacingOccurrences(of: "<think>", with: "")
                .replacingOccurrences(of: "</think>", with: "")
        }
        
        return message
    }

    /// Calculates and returns the model's approximate size in gigabytes (GB).
    ///
    /// - Returns: A Decimal value representing the model size in GB, or `nil` if not defined.
    public var modelSize: Decimal? {
        let allModels = CoreModels.available + ReasoningModels.available + VisionModels.available + AudioModels.available + EmbeddingModels.available
        if let model = allModels.first(where: { $0.name == self.name }) {
            return Decimal(model.size) / Decimal(1024 * 1024 * 1024)
        }
        return nil
    }
}
