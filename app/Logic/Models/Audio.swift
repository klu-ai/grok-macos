//
//  Audio.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages the collection of available audio processing models for speech recognition,
//  synthesis, and multilingual audio processing. This component serves as the
//  central registry for all audio-related AI models.
//
//  Key features:
//  - Speech recognition models (Whisper)
//  - Text-to-speech synthesis (Bark, FastSpeech)
//  - Multilingual speech processing (Seamless)
//
//  Model capabilities:
//  - Speech-to-text transcription
//  - Text-to-speech generation
//  - Multilingual translation
//  - Real-time audio processing
//
//  Usage notes:
//  - Access models through AudioModels.available
//  - Default model optimized for general transcription
//  - Models selected based on task requirements
//

import Foundation

/// Provider of audio processing and speech models
public struct AudioModels {
    /// Available audio models
    public static let available: [Model] = [
        Model(name: "openai_whisper-large-v3-v20240930_turbo", displayName: "Whisper Large V3 Turbo", lab: "OpenAI", sizeInGB: 1.61, description: "Efficient Whisper model for speech processing", gguf: "", mlx: "argmaxinc/whisperkit-coreml/tree/main/openai_whisper-large-v3-v20240930_turbo")
    ]
    
    /// Default audio model name
    public static let defaultModel = "openai_whisper-large-v3-v20240930_turbo"
} 
