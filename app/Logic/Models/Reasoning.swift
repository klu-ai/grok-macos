//
//  Reasoning.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Provides specialized reasoning and decision-making models for complex
//  problem-solving tasks. This component manages models optimized for
//  logical reasoning, inference, and structured thinking.
//
//  Model categories:
//  - General reasoning (DeepSeek)
//  - Advanced reasoning (DeepHermes)
//
//  Capabilities:
//  - Complex problem solving
//  - Logical deduction
//  - Multi-step reasoning
//  - Decision making
//  - Inference chains
//
//  Usage notes:
//  - Access through ReasoningModels.available
//  - Models optimized for different reasoning tasks
//  - Select based on complexity requirements
//  - Consider resource constraints
//
import Foundation

/// Provider of specialized reasoning models
public struct ReasoningModels {
    /// Available reasoning models
    public static let available: [Model] = [
        Model(name: "deepseek-r1-distill-qwen-1.5b-4bit", displayName: "DeepSeek R1 Distill Qwen 1.5B (4-bit)", lab: "DeepSeek", sizeInGB: 1.0, description: "Efficient reasoning model from DeepSeek", gguf: "", mlx: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-4bit"),
        Model(name: "deepseek-r1-distill-qwen-1.5b-8bit", displayName: "DeepSeek R1 Distill Qwen 1.5B (8-bit)", lab: "DeepSeek", sizeInGB: 1.9, description: "Higher precision DeepSeek reasoning model", gguf: "", mlx: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-8bit"),
        Model(name: "DeepHermes-3-Llama-3-8B-Preview-4Bit", displayName: "Deep Hermes 3 Llama 3 8B Preview (4-bit)", lab: "Nous Research", sizeInGB: 4.52, description: "Reasoning with function calling and JSON capabilities", gguf: "", mlx: "mlx-community/DeepHermes-3-Llama-3-8B-Preview-4Bit"),
        Model(name: "Dolphin3.0-R1-Mistral-24B-6bit", displayName: "Dolphin 3.0 R1 Mistral 24B (6-bit)", lab: "Cognitive Computations", sizeInGB: 19.15, description: "Advanced conversational reasoning model based on Mistral architecture", gguf: "", mlx: "mlx-community/Dolphin3.0-R1-Mistral-24B-6bit"),
        Model(name: "DeepSeek-R1-Distill-Qwen-32B-4bit", displayName: "DeepSeek R1 Distill Qwen 32B (4-bit)", lab: "DeepSeek", sizeInGB: 18.44, description: "Large-scale reasoning model with advanced capabilities", gguf: "", mlx: "mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit"),
        Model(name: "DeepSeek-R1-Distill-Qwen-32B-MLX-8Bit", displayName: "DeepSeek R1 Distill Qwen 32B (8-bit)", lab: "DeepSeek", sizeInGB: 35.0, description: "High-precision large-scale reasoning model with enhanced capabilities", gguf: "", mlx: "mlx-community/DeepSeek-R1-Distill-Qwen-32B-MLX-8Bit")
    ]
    
    /// Default reasoning model name
    public static let defaultModel = "DeepHermes-3-Llama-3-8B-Preview-4Bit"
} 
