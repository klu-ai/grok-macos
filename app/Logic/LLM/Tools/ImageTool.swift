//
//  ImageTool.swift
//  klu
//
//  Created by Stephen M. Walker II on 3/13/25.
//
//  Description:
//  This file provides image analysis functionality as a tool for the RunLLM class.
//  It handles analyzing images using a vision language model.
//
//  Usage:
//  - Used by the FunctionCalls.swift for the analyze_image tool.
//  - Analyzes images from a specified path.
//
//  Dependencies:
//  - Foundation: Provides core functionality.
//  - MLXLMCommon: Supplies shared definitions and types for LLM model configuration and inference.
//  - MLXVLM: Provides vision language model support.
//  - CoreGraphics: Provides image sizing types.

import Foundation
import MLX
import MLXLLM
import MLXVLM
import MLXLMCommon
import SwiftUI
import CoreGraphics

/// Extension to RunLLM class providing image analysis capabilities
extension RunLLM {
    /// Analyzes an image using a vision language model
    func analyzeImage(imagePath: String) async throws -> String {
        print("Analyzing image from: \(imagePath)")
        let fileURL = URL(fileURLWithPath: imagePath)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let _ = CIImage(contentsOf: fileURL) else {
            throw RunLLMError.invalidParameters("Invalid image at path: \(imagePath)")
        }
        
        let vlmModelName = VisionModels.defaultModel
        print("Loading vision model: \(vlmModelName)")
        let modelContainer = try await load(modelName: vlmModelName)
        
        let analysisPrompt = "Analyze the image and describe its contents in detail."
        var userInput = UserInput(messages: [
            ["role": "user", "content": "[{\"type\": \"text\", \"text\": \"\(analysisPrompt)\"}, {\"type\": \"image\", \"image_url\": \"\(imagePath)\"}]"]
        ])
        userInput.processing = UserInput.Processing(resize: CGSize(width: 448, height: 448))
        
        // Create a local copy to avoid Swift 6 concurrency capture issues
        let localUserInput = userInput
        
        print("Generating image analysis...")
        let result = try await modelContainer.perform { context in
            let input = try await context.processor.prepare(input: localUserInput)
            return try MLXLMCommon.generate(
                input: input,
                parameters: self.generateParameters,
                context: context,
                didGenerate: { tokens in
                    return .stop // Default behavior; adjust if streaming is needed
                }
            )
        }
        print("Image analysis completed successfully")
        return result.output
    }
} 