import Foundation
import MLX
import AVFoundation

/// Main entry point for speech synthesis functionality
public final class SpeechEngine {
    
    /// Shared instance for convenient access
    public static let shared = SpeechEngine()
    
    // Cache of loaded models to avoid reloading
    private var modelCache: [ModelIdentifier: any SpeechModel] = [:]
    
    // Private directories for model storage
    private let modelsDirectory: URL
    private let outputDirectory: URL
    
    // Configuration for the engine
    public var configuration: Configuration
    
    /// Configuration options for the speech engine
    public struct Configuration {
        /// Whether to cache models in memory after loading
        public var cacheModelsInMemory: Bool = true
        
        /// Whether to preload voices when selecting a model
        public var preloadVoices: Bool = false
        
        /// Sample rate for audio output
        public var defaultSampleRate: Int = 24000
        
        /// Default model to use if none specified
        public var defaultModel: ModelIdentifier = .kokoroSmall4Bit
        
        /// Default voice to use if none specified
        public var defaultVoice: VoiceIdentifier = .afHeart
        
        public init() {}
    }
    
    /// Initialize the speech engine
    /// - Parameter configuration: Optional configuration options
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        
        // Setup directories
        let baseDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".speechkit", isDirectory: true)
        
        modelsDirectory = baseDirectory.appendingPathComponent("models", isDirectory: true)
        outputDirectory = baseDirectory.appendingPathComponent("outputs", isDirectory: true)
        
        // Create directories if needed
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }
    
    /// Get a speech model, loading it if necessary
    /// - Parameter modelId: The ID of the model to load
    /// - Returns: A speech model instance
    public func getModel(_ modelId: ModelIdentifier = .kokoroSmall4Bit) async throws -> any SpeechModel {
        // Check cache first
        if configuration.cacheModelsInMemory, let cachedModel = modelCache[modelId] {
            return cachedModel
        }
        
        // Load the model
        let model = try await loadModel(modelId)
        
        // Cache the model if configured to do so
        if configuration.cacheModelsInMemory {
            modelCache[modelId] = model
        }
        
        return model
    }
    
    /// Generate speech from text using the default model and voice
    /// - Parameters:
    ///   - text: The text to convert to speech
    ///   - voice: Optional voice to use (defaults to configuration setting)
    ///   - speed: Speed multiplier (0.5-2.0, defaults to 1.0)
    ///   - modelId: Optional model ID to use (defaults to configuration setting)
    /// - Returns: Generated audio data and metadata
    public func speak(
        _ text: String,
        voice: VoiceIdentifier? = nil,
        speed: Float = 1.0,
        modelId: ModelIdentifier? = nil
    ) async throws -> SpeechAudio {
        let selectedModel = try await getModel(modelId ?? configuration.defaultModel)
        let selectedVoice = voice ?? configuration.defaultVoice
        
        // Validate parameters
        guard !text.isEmpty else {
            throw SpeechError.invalidParameters("Text cannot be empty")
        }
        
        guard (0.5...2.0).contains(speed) else {
            throw SpeechError.invalidParameters("Speed must be between 0.5 and 2.0")
        }
        
        guard selectedModel.availableVoices.contains(selectedVoice) else {
            throw SpeechError.invalidParameters("Voice \(selectedVoice.rawValue) not available for this model")
        }
        
        // Generate speech
        let audio = try await selectedModel.synthesize(
            text: text,
            voice: selectedVoice,
            speed: speed
        )
        
        return audio
    }
    
    /// Play speech audio using AVFoundation
    /// - Parameter audio: The speech audio to play
    /// - Returns: The AVAudioPlayer instance for controlling playback
    @discardableResult
    public func play(_ audio: SpeechAudio) throws -> AVAudioPlayer {
        let player = try AVAudioPlayer(data: audio.audioData)
        player.play()
        return player
    }
    
    /// Save speech audio to a file
    /// - Parameters:
    ///   - audio: The speech audio to save
    ///   - filename: Optional filename (defaults to a generated name)
    /// - Returns: URL where the file was saved
    public func save(_ audio: SpeechAudio, filename: String? = nil) throws -> URL {
        let outputFilename = filename ?? "speech_\(UUID().uuidString).wav"
        let outputURL = outputDirectory.appendingPathComponent(outputFilename)
        
        try audio.audioData.write(to: outputURL)
        return outputURL
    }
    
    /// Clear the model cache to free memory
    public func clearModelCache() {
        modelCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Load a model from disk or download if necessary
    private func loadModel(_ modelId: ModelIdentifier) async throws -> any SpeechModel {
        // This is where we'd implement the model loading logic
        // For now, we'll create a placeholder implementation
        
        // In the real implementation, this would:
        // 1. Check if model exists locally
        // 2. Download if needed
        // 3. Load weights and config
        // 4. Initialize the appropriate model type
        
        // For this prototype, we'll return a concrete implementation
        return KokoroSpeechModel(modelId: modelId)
    }
}