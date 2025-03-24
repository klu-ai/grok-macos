//
//  CoreModels.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Provides a centralized registry of available language models for the application.
//  This component maintains the catalog of supported AI models and their specifications,
//  serving as the source of truth for model availability and defaults.
//
//  Key responsibilities:
//  - Defines available language models and their specifications
//  - Provides default model selection
//  - Maintains model metadata (size, descriptions)
//  - Centralizes model configuration
//
//  Model categories:
//  - Llama models (Meta's language models)
//  - Mistral models (various sizes)
//  - Other open source models (Qwen, Granite, Gemma)
//
//  Usage notes:
//  - Access available models through CoreModels.available
//  - Use defaultModel for initial/fallback configuration
//  - Models are immutable after initialization

import Foundation

/// Provider of core language models
public struct CoreModels {
    /// Available core language models
    public static let available: [Model] = [
        Model(name: "Llama-3.2-1B-Instruct-4bit", displayName: "Llama 3.2 1B Instruct (4-bit)", lab: "Meta", sizeInGB: 0.7, description: "Smallest, lightweight Llama model", gguf: "", mlx: "mlx-community/Llama-3.2-1B-Instruct-4bit"),
        Model(name: "Llama-3.2-3B-Instruct-4bit", displayName: "Llama 3.2 3B Instruct (4-bit)", lab: "Meta", sizeInGB: 1.8, description: "Lightweight Llama model", gguf: "", mlx: "mlx-community/Llama-3.2-3B-Instruct-4bit"),
        Model(name: "Hermes-3-Llama-3.2-3B-bf16", displayName: "Hermes 3 Llama 3.2 3B (bf16)", lab: "Nous Research", sizeInGB: 6.43, description: "Hermes-3 improved instruction following", gguf: "", mlx: "mlx-community/Hermes-3-Llama-3.2-3B-bf16"),
        Model(name: "Llama-3.3-70B-Instruct-4bit", displayName: "Llama 3.3 70B Instruct (4-bit)", lab: "Meta", sizeInGB: 39.7, description: "Medium-sized Llama model for advanced reasoning", gguf: "", mlx: "mlx-community/Llama-3.3-70B-Instruct-4bit"),
        Model(name: "gemma-2-27b-it-4bit", displayName: "Gemma 2 27B IT (4-bit)", lab: "Google", sizeInGB: 15.32, description: "Instruction-tuned model optimized for conversational AI", gguf: "", mlx: "mlx-community/gemma-2-27b-it-4bit"),
        Model(name: "phi-4-4bit", displayName: "Phi 4 (4-bit)", lab: "Microsoft", sizeInGB: 8.25, description: "Optimized for code, math, and conversational tasks", gguf: "", mlx: "mlx-community/phi-4-4bit"),
        Model(name: "phi-4-8bit", displayName: "Phi 4 (8-bit)", lab: "Microsoft", sizeInGB: 15.57, description: "Higher precision Phi-4 model for code, math, and conversational tasks", gguf: "", mlx: "mlx-community/phi-4-8bit"),
        Model(name: "mistral-small-24b-instruct-2501-4bit", displayName: "Mistral Small 24B Instruct (4-bit)", lab: "Mistral AI", sizeInGB: 13.3, description: "Mistral model optimized for instruction-following", gguf: "", mlx: "mlx-community/Mistral-Small-24B-Instruct-2501-4bit"),
        Model(name: "mistral-small-24b-instruct-2501-8bit", displayName: "Mistral Small 24B Instruct (8-bit)", lab: "Mistral AI", sizeInGB: 25.03, description: "Higher precision Mistral model for improved instruction-following", gguf: "", mlx: "mlx-community/Mistral-Small-24B-Instruct-2501-8bit"),
        Model(name: "DeepSeek-R1-Distill-Qwen-32B-4bit", displayName: "DeepSeek R1 Distill Qwen 32B (4-bit)", lab: "DeepSeek", sizeInGB: 18.44, description: "Large-scale reasoning model with advanced capabilities", gguf: "", mlx: "mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit"),
        Model(name: "Qwen2.5-32B-Instruct-4bit", displayName: "Qwen 2.5 32B Instruct (4-bit)", lab: "Qwen", sizeInGB: 18.44, description: "Powerful conversational model with strong chat capabilities", gguf: "", mlx: "mlx-community/Qwen2.5-32B-Instruct-4bit"),
        Model(name: "QwQ-32B-4bit", displayName: "QwQ 32B (4-bit)", lab: "Qwen", sizeInGB: 18.44, description: "Conversational model with strong chat capabilities in 4-bit precision", gguf: "", mlx: "mlx-community/QwQ-32B-4bit"),
        Model(name: "Qwen2.5-QwQ-35B-Eureka-Cubed-abliterated-uncensored-4bit", displayName: "Qwen 2.5 QwQ 35B Eureka Cubed (4-bit)", lab: "Qwen", sizeInGB: 19.54, description: "Uncensored model with enhanced reasoning and thinking capabilities", gguf: "", mlx: "mlx-community/Qwen2.5-QwQ-35B-Eureka-Cubed-abliterated-uncensored-4bit"),
        Model(name: "watt-tool-8B", displayName: "Watt Tool 8B", lab: "Watt", sizeInGB: 4.52, description: "Specialized for function-calling and tool-use capabilities", gguf: "", mlx: "mlx-community/watt-tool-8B")
    ]
    
    /// Default core model name
    public static let defaultModel = "mistral-small-24b-instruct-2501-4bit"
} 
