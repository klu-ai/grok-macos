//
//  ReasoningTool.swift
//  klu
//
//  Created by Stephen M. Walker II on 3/13/25.
//
//  Description:
//  This file provides step-by-step reasoning functionality as a tool for the RunLLM class.
//  It handles complex reasoning tasks using a dedicated model.
//
//  Usage:
//  - Used by the FunctionCalls.swift for the perform_reasoning tool.
//  - Processes complex reasoning problems with detailed step-by-step thinking.
//
//  Dependencies:
//  - Foundation: Provides core functionality.
//  - MLXLMCommon: Supplies shared definitions and types for LLM model configuration and inference.

import Foundation
import MLX
import MLXLLM
import MLXLMCommon

/// Extension to RunLLM class providing reasoning capabilities
extension RunLLM {
    /// Performs step-by-step reasoning using a dedicated reasoning model
    func performReasoning(problem: String) async throws -> String {
        print("Performing reasoning for problem: \(problem)")
        let reasoningModelName = ReasoningModels.defaultModel
        print("Loading reasoning model: \(reasoningModelName)")
        let modelContainer = try await load(modelName: reasoningModelName)
        
        // GPT4.5 prompt
        let reasoningPrompt = "You are a highly capable, thoughtful, and precise assistant. Your goal is to deeply understand the user's intent, ask clarifying questions when needed, think step-by-step through complex problems, provide clear and accurate answers, and proactively anticipate helpful follow-up information. Always prioritize being truthful, nuanced, insightful, and efficient, tailoring your responses specifically to the user's needs and preferences. Think about the following problem step by step."
        let messages: [[String: String]] = [
            ["role": "system", "content": reasoningPrompt],
            ["role": "user", "content": "Reason about this problem for the user: \(problem)"]
        ]
        
        var reasoningTask: Task<String, Error>?
        
        reasoningTask = Task {
            let result = try await modelContainer.perform { context in
                let input = try await context.processor.prepare(input: UserInput(messages: messages))
                var thinkingTrace = ""
                var foundThinking = false
                
                return try MLXLMCommon.generate(
                    input: input,
                    parameters: self.generateParameters,
                    context: context,
                    didGenerate: { tokens in
                        if Task.isCancelled {
                            return .stop
                        }
                        let text = context.tokenizer.decode(tokens: tokens)
                        if text.contains("<think>") {
                            foundThinking = true
                        } else if text.contains("</think>") {
                            return .stop
                        } else if foundThinking {
                            thinkingTrace += text
                        }
                        return .more
                    }
                )
            }
            print("Reasoning completed successfully")
            return "<think>\n\(result.output)\n</think>"
        }
        
        return try await reasoningTask!.value
    }
} 