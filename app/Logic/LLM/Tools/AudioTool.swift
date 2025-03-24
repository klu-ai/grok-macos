//
//  AudioTool.swift
//  klu
//
//  Created by Stephen M. Walker II on 3/13/25.
//
//  Description:
//  This file provides audio transcription functionality as a tool for the RunLLM class.
//  It handles transcribing audio files using the Whisper model.
//
//  Usage:
//  - Used by the FunctionCalls.swift for the transcribe_audio tool.
//  - Transcribes audio files from a specified path.
//
//  Dependencies:
//  - Foundation: Provides core functionality.
//  - MLXLMCommon: Supplies shared definitions and types for LLM model configuration and inference.

import Foundation
import MLX
import MLXLLM
import MLXLMCommon

/// Extension to RunLLM class providing audio transcription capabilities
extension RunLLM {
    /// Transcribes audio using the Whisper model from AudioModels
    func transcribeAudio(audioPath: String) async throws -> String {
        print("Transcribing audio from: \(audioPath)")
        let fileURL = URL(fileURLWithPath: audioPath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw RunLLMError.invalidParameters("Audio file does not exist at path: \(audioPath)")
        }
        
        let whisperModelName = AudioModels.defaultModel
        print("Loading Whisper model: \(whisperModelName)")
        let modelContainer = try await load(modelName: whisperModelName)
        
        let transcriptionPrompt = "Transcribe the audio precisely, including speaker indicators if multiple speakers are present."
        let messages: [[String: String]] = [
            ["role": "system", "content": transcriptionPrompt],
            ["role": "user", "content": "Transcribe this audio file."]
        ]
        
        let userInput = UserInput(messages: messages)
        print("Generating audio transcription...")
        
        let result = try await modelContainer.perform { context in
            let input = try await context.processor.prepare(input: userInput)
            return try MLXLMCommon.generate(
                input: input,
                parameters: self.generateParameters,
                context: context,
                didGenerate: { tokens in
                    return .stop // Default behavior; adjust if streaming is needed
                }
            )
        }
        print("Transcription completed successfully")
        return result.output
    }
} 