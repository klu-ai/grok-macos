import Foundation
import MLX

/// Error types specific to speech synthesis
public enum SpeechError: Error {
    case modelLoadFailed(String)
    case synthesisError(String)
    case invalidParameters(String)
    case audioConversionFailed
}

/// Protocol defining core capabilities of a speech synthesis model
public protocol SpeechModel {
    /// The unique identifier for this model
    var modelId: ModelIdentifier { get }
    
    /// Synthesize speech from text
    /// - Parameters:
    ///   - text: The text to convert to speech
    ///   - voice: Voice identifier to use
    ///   - speed: Speed multiplier (0.5 to 2.0)
    /// - Returns: Generated audio data and any associated metadata
    func synthesize(
        text: String,
        voice: VoiceIdentifier,
        speed: Float
    ) async throws -> SpeechAudio
    
    /// Get available voices for this model
    var availableVoices: [VoiceIdentifier] { get }
}

/// Strongly typed identifier for models
public struct ModelIdentifier: Hashable, Equatable, Sendable {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public static let kokoroSmall4Bit = ModelIdentifier("mlx-community/Kokoro-82M-4bit")
    public static let kokoroSmall6Bit = ModelIdentifier("mlx-community/Kokoro-82M-6bit")
    public static let kokoroSmall8Bit = ModelIdentifier("mlx-community/Kokoro-82M-8bit")
    public static let kokoroSmallFloat = ModelIdentifier("mlx-community/Kokoro-82M-bf16")
}

/// Strongly typed identifier for voices
public struct VoiceIdentifier: Hashable, Equatable, Sendable {
    public let rawValue: String
    public let language: LanguageCode
    
    public init(_ rawValue: String, language: LanguageCode) {
        self.rawValue = rawValue
        self.language = language
    }
    
    public static let afHeart = VoiceIdentifier("af_heart", language: .americanEnglish)
    public static let afNova = VoiceIdentifier("af_nova", language: .americanEnglish)
    public static let afBella = VoiceIdentifier("af_bella", language: .americanEnglish)
    public static let bfEmma = VoiceIdentifier("bf_emma", language: .britishEnglish)
}

/// Language codes supported by the models
public enum LanguageCode: String, Sendable {
    case americanEnglish = "a"
    case britishEnglish = "b"
    case japanese = "j"
    case mandarin = "z"
    
    public var description: String {
        switch self {
        case .americanEnglish: 
            return "American English"
        case .britishEnglish:
            return "British English"
        case .japanese:
            return "Japanese"
        case .mandarin:
            return "Mandarin Chinese"
        }
    }
}

/// Container for generated speech audio and associated metadata
public struct SpeechAudio {
    public let audioData: Data
    public let sampleRate: Int
    public let text: String
    public let phonemes: String?
    public let voiceId: VoiceIdentifier
    
    public init(
        audioData: Data,
        sampleRate: Int,
        text: String,
        phonemes: String? = nil,
        voiceId: VoiceIdentifier
    ) {
        self.audioData = audioData
        self.sampleRate = sampleRate
        self.text = text
        self.phonemes = phonemes
        self.voiceId = voiceId
    }
}

/// Status of a speech synthesis task
public enum SynthesisStatus {
    case notStarted
    case processing(progress: Double)
    case completed(SpeechAudio)
    case failed(Error)
}