//
//  Vision.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Provides a comprehensive collection of vision-language models for image understanding,
//  analysis, and multimodal interactions. This component manages all vision-related
//  AI models and their configurations.
//
//  Model categories:
//  - Large vision-language models (Pixtral from Mistral)
//  - Multimodal conversational models (UI-TARS, Qwen2.5-VL)
//
//  Capabilities:
//  - Image understanding and analysis
//  - Visual question answering
//  - Image-text generation
//  - Scene understanding
//  - Object detection and recognition
//
//  Usage notes:
//  - Access through VisionModels.available
//  - Models range from lightweight to high-capacity
//  - Default model balances quality and performance
//  - Select based on memory constraints and accuracy needs

import Foundation

/// Provider of vision and image processing models
public struct VisionModels {
    /// Available vision models
    public static let available: [Model] = [
        Model(name: "pixtral-12b-4bit", displayName: "Pixtral 12B (4-bit)", lab: "Mistral AI", sizeInGB: 7.14, description: "Vision language model from Mistral", gguf: "", mlx: "mlx-community/pixtral-12b-4bit"),
        Model(name: "UI-TARS-7B-DPO-8bit", displayName: "UI-TARS 7B DPO (8-bit)", lab: "Universal Intellect", sizeInGB: 9.45, description: "Image-Text-to-Text multimodal conversational model", gguf: "", mlx: "mlx-community/UI-TARS-7B-DPO-8bit"),
        Model(name: "Qwen2.5-VL-7B-Instruct-8bit", displayName: "Qwen 2.5 VL 7B Instruct (8-bit)", lab: "Alibaba Cloud", sizeInGB: 8.94, description: "Multimodal conversational model with strong image understanding capabilities", gguf: "", mlx: "mlx-community/Qwen2.5-VL-7B-Instruct-8bit"),
        Model(name: "gemma-3-12b-it-4bit", displayName: "Gemma 3 12B IT (4-bit)", lab: "Google", sizeInGB: 5.37, description: "Conversational model optimized for image-text tasks", gguf: "", mlx: "mlx-community/gemma-3-12b-it-4bit"),
        Model(name: "gemma-3-4b-it-8bit", displayName: "Gemma 3 4B IT (8-bit)", lab: "Google", sizeInGB: 4.96, description: "Conversational model optimized for image-text tasks", gguf: "", mlx: "mlx-community/gemma-3-4b-it-8bit"),
        Model(name: "Qwen2.5-VL-7B-Instruct-bf16", displayName: "Qwen 2.5 VL 7B Instruct (bf16)", lab: "Alibaba Cloud", sizeInGB: 16.58, description: "Advanced multimodal conversational model with strong image understanding capabilities", gguf: "", mlx: "mlx-community/Qwen2.5-VL-7B-Instruct-bf16")
    ]
    
    /// Default vision model name
    public static let defaultModel = "gemma-3-12b-it-4bit"
} 
