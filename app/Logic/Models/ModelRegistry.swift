//
//  ModelRegistry.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/23/25.
//
//  Description:
//  This file defines the ModelRegistry class, which serves as a central registry for managing
//  AI models across different types within the application. It provides functionality to
//  retrieve available models and default model names for each model type.
//
//  Core responsibilities:
//  - Defines the types of models supported by the application
//  - Manages a registry of available models for each type
//  - Provides access to default model names for each type
//
//  Usage:
//  - Use ModelRegistry.shared to access the singleton instance
//  - Call getModels(for:) to retrieve models of a specific type
//  - Call getDefaultModel(for:) to retrieve the default model name for a specific type
//
//  Dependencies:
//  - Foundation for basic data structures and functionality
//

import Foundation

/// Defines the types of models supported by the application
enum ModelType: String, CaseIterable {
    case core, reasoning, vision, audio, embedding
}

/// Central registry for managing AI models across different types
class ModelRegistry {
    static let shared = ModelRegistry()
    
    private init() {}
    
    /// Dictionary mapping model types to their available models
    let models: [ModelType: [Model]] = [
        .core: CoreModels.available,
        .reasoning: ReasoningModels.available,
        .vision: VisionModels.available,
        .audio: AudioModels.available,
        .embedding: EmbeddingModels.available
    ]
    
    /// Dictionary mapping model types to their default model names
    let defaultModels: [ModelType: String] = [
        .core: CoreModels.defaultModel,
        .reasoning: ReasoningModels.defaultModel,
        .vision: VisionModels.defaultModel,
        .audio: AudioModels.defaultModel,
        .embedding: EmbeddingModels.defaultModel
    ]
    
    /// Retrieves the list of models for a given type
    func getModels(for type: ModelType) -> [Model] {
        return models[type] ?? []
    }
    
    /// Retrieves the default model name for a given type
    func getDefaultModel(for type: ModelType) -> String {
        return defaultModels[type] ?? ""
    }
}