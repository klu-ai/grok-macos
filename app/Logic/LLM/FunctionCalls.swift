//
//  FunctionCalls.swift
//  MLX function calling implementation
//
//  Created by Stephen M. Walker II on 3/4/25.
//
//  Description:
//  This file provides function calling capabilities for the RunLLM class.
//  It handles tool call extraction, execution, and result processing.
//  These utilities support proper handling of function/tool calls during LLM inference.
//
//  Usage:
//  - Used internally by the RunLLM class for function calling support.
//  - Extracts tool calls from model outputs using regex patterns.
//  - Executes tool functions and returns formatted results.
//
//  Dependencies:
//  - Foundation: Provides core functionality.
//  - MLXLMCommon: Supplies shared definitions and types for LLM model configuration and inference.

import Foundation
import MLXLMCommon
//import MLX
//import MLXLLM
//import MLXRandom
//import SwiftUI

/// Extension to RunLLM class for function/tool calling capabilities
extension RunLLM {
    /// Represents a tool call extracted from model output
    struct ToolCall {
        let id: String
        let name: String
        let parameters: [String: Any]
    }
    
    /// Extracts tool calls from the model's output
    func extractToolCalls(from output: String) -> [ToolCall]? {
        let pattern = #"```json\n(.*?)\n```"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let matches = regex?.matches(in: output, range: NSRange(output.startIndex..., in: output))
        
        var toolCalls: [ToolCall] = []
        for match in matches ?? [] {
            if match.numberOfRanges == 2,
            let range = Range(match.range(at: 1), in: output) {
                let jsonString = String(output[range])
                if let jsonData = jsonString.data(using: .utf8),
                let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                let id = jsonObject["id"] as? String,
                let name = jsonObject["name"] as? String,
                let parameters = jsonObject["parameters"] as? [String: Any] {
                    let toolCall = ToolCall(id: id, name: name, parameters: parameters)
                    toolCalls.append(toolCall)
                }
            }
        }
        return toolCalls.isEmpty ? nil : toolCalls
    }
    
    /// Executes a tool based on its name and parameters
    func executeTool(_ toolCall: ToolCall) async throws -> String {
        // Print initial message for debugging
        print("Executing tool: \(toolCall.name) with parameters: \(toolCall.parameters)")
        
        switch toolCall.name {
        case "transcribe_audio":
            guard let audioPath = toolCall.parameters["audio_path"] as? String else {
                throw RunLLMError.invalidParameters("Missing audio_path parameter for transcribe_audio")
            }
            do {
                return try await transcribeAudio(audioPath: audioPath)
            } catch {
                print("Error in transcribeAudio: \(error)")
                throw error
            }
            
        case "analyze_image":
            guard let imagePath = toolCall.parameters["image_path"] as? String else {
                throw RunLLMError.invalidParameters("Missing image_path parameter for analyze_image")
            }
            do {
                return try await analyzeImage(imagePath: imagePath)
            } catch {
                print("Error in analyzeImage: \(error)")
                throw error
            }
            
        case "perform_reasoning":
            guard let problem = toolCall.parameters["problem"] as? String else {
                throw RunLLMError.invalidParameters("Missing problem parameter for perform_reasoning")
            }
            do {
                return try await performReasoning(problem: problem)
            } catch {
                print("Error in performReasoning: \(error)")
                throw error
            }
            
        case "list_files":
            guard let directory = toolCall.parameters["directory"] as? String else {
                throw RunLLMError.invalidParameters("Missing directory parameter for list_files")
            }
            do {
                // This function doesn't load a model, so wrapped separately
                return try listFiles(directory: directory)
            } catch {
                print("Error in listFiles: \(error)")
                throw error
            }
            
        default:
            print("Unknown tool function: \(toolCall.name)")
            throw RunLLMError.unknownFunction(toolCall.name)
        }
    }
    
    /// Generates text using the base model without tool execution
    func generateText(modelContainer: ModelContainer, messages: [[String: String]]) async throws -> String {
        return try await modelContainer.perform { context in
            let input = try await context.processor.prepare(input: UserInput(messages: messages))
            var lastTokenCount = 0
            
            let result = try MLXLMCommon.generate(
                input: input,
                parameters: self.generateParameters,
                context: context,
                didGenerate: { tokens in
                    if Task.isCancelled {
                        return .stop
                    }
                    if tokens.count >= self.maxTokens {
                        return .stop
                    }
                    if tokens.count % self.displayEveryNTokens == 0 {
                        let newTokens = Array(tokens[lastTokenCount..<tokens.count])
                        lastTokenCount = tokens.count
                        let partialText = context.tokenizer.decode(tokens: newTokens)
                        
                        Task { @MainActor in
                            self.output += partialText
                        }
                    }
                    return .more
                }
            )
            
            return result.output
        }
    }
}