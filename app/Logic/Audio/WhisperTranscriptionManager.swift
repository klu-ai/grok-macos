import Foundation
import SwiftUI
import WhisperKit

/// A manager that handles loading the WhisperKit model and performing audio transcription.
/// This class is separate from RunLLM, so it can load the audio model without conflicting with main LLM usage.
@MainActor
class WhisperTranscriptionManager: ObservableObject {
    static let shared = WhisperTranscriptionManager()

    /// Flag to indicate if the WhisperKit model is loaded
    @Published var isModelLoaded: Bool = false

    /// Status text or progress for UI
    @Published var status: String = ""

    /// Error message to display in the UI
    @Published var errorMessage: String? = nil

    private var whisperKit: WhisperKit?

    @Published var modelDownloadProgress: Double = 1.0
    @Published var isDownloadingModel: Bool = false

    private init() { }

    /// Loads the WhisperKit model if not already loaded
    func loadWhisperModel() async {
        guard !isModelLoaded else { return }
        self.status = "Loading WhisperKit model..."
        do {
            // Provide any custom config or pass model name if needed
            let config = WhisperKitConfig(
                model: AudioModels.defaultModel,  // Using default model from AudioModels
                downloadBase: nil,
                modelRepo: nil,
                modelToken: nil,
                modelFolder: nil,
                tokenizerFolder: nil,
                computeOptions: nil,
                audioProcessor: nil,
                featureExtractor: nil,
                audioEncoder: nil,
                textDecoder: nil,
                logitsFilters: nil,
                segmentSeeker: nil,
                voiceActivityDetector: nil,
                verbose: true,
                logLevel: .info,
                prewarm: nil,
                load: true,
                download: true,
                useBackgroundDownloadSession: false
            )
            self.isDownloadingModel = true
            self.modelDownloadProgress = 0.0
            
            // We'll pick a variant from config.model or fallback
            let variantName = config.model ?? "openai_whisper-large-v3-v20240930_turbo"

            // First, download the model with a progress callback, and store the returned folder URL
            let downloadURL = try await WhisperKit.download(
                variant: variantName,
                downloadBase: config.downloadBase,
                useBackgroundSession: config.useBackgroundDownloadSession,
                from: config.modelRepo ?? "argmaxinc/whisperkit-coreml",
                token: config.modelToken
            ) { progress in
                if progress.totalUnitCount > 0 {
                    let fraction = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    Task { @MainActor in
                        self.modelDownloadProgress = fraction
                        self.status = "Downloading model: \((fraction*100).rounded())%"
                    }
                }
            }

            // Update config.modelFolder so WhisperKit init uses that path
            config.modelFolder = downloadURL.path

            // After download finishes, proceed to create WhisperKit instance
            let kit = try await WhisperKit(config)
            
            // Mark complete on main actor
            Task { @MainActor in
                self.isDownloadingModel = false
                self.modelDownloadProgress = 1.0
                self.whisperKit = kit
                self.isModelLoaded = true
                self.status = "WhisperKit model loaded"
            }
        } catch {
            self.status = "Failed to load WhisperKit: \(error.localizedDescription)"
        }
    }

    /// Transcribes the given 16kHz mono audio data with the loaded WhisperKit model
    /// - Parameter audioBuffer: A float array in 16kHz mono format
    /// - Returns: A string of recognized text
    func transcribeAudioData(_ audioBuffer: [Float]) async -> String {
        guard let kit = whisperKit, isModelLoaded else {
            return "Model not loaded."
        }
        do {
            // If needed, pass decode options. By default, this calls the entire pipeline
            let results = try await kit.transcribe(audioArray: audioBuffer)
            // Join together the text from each returned segment
            let joinedText = results.map { $0.text }.joined(separator: " ")
            return joinedText.isEmpty ? "(no speech detected)" : joinedText
        } catch {
            return "Transcription error: \(error.localizedDescription)"
        }
    }
}