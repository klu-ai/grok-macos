import Foundation

/// An example showing how to use SpeechKit in a Swift application
public final class SpeechKitExample {
    private let engine = SpeechEngine.shared
    
    /// Run basic text-to-speech synthesis
    public func simpleSpeech() async {
        do {
            // Basic usage with default settings
            let audio = try await engine.speak("Hello, world! This is a test of SpeechKit.")
            try engine.play(audio)
            
            // Wait for audio to finish playing
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            print("Speech completed successfully!")
        } catch {
            print("Speech synthesis failed: \(error)")
        }
    }
    
    /// Run advanced example with custom settings
    public func advancedSpeech() async {
        do {
            // Get specific model
            let model = try await engine.getModel(.kokoroSmall8Bit)
            
            // Set up a series of phrases with different voices
            let phrases = [
                (text: "This is the AF Heart voice.", voice: VoiceIdentifier.afHeart),
                (text: "Now I'm speaking with the AF Nova voice.", voice: VoiceIdentifier.afNova),
                (text: "Switching to AF Bella now.", voice: VoiceIdentifier.afBella),
                (text: "And finally, the British English voice, BF Emma.", voice: VoiceIdentifier.bfEmma)
            ]
            
            // Process each phrase
            for (index, phrase) in phrases.enumerated() {
                print("Generating phrase \(index + 1) with \(phrase.voice.rawValue)...")
                
                // Synthesize speech
                let audio = try await model.synthesize(
                    text: phrase.text,
                    voice: phrase.voice,
                    speed: 1.0
                )
                
                // Play the speech
                try engine.play(audio)
                
                // Save to file
                let fileURL = try engine.save(audio, filename: "example_\(phrase.voice.rawValue).wav")
                print("Saved to: \(fileURL.path)")
                
                // Wait for audio to finish
                try await Task.sleep(nanoseconds: 3_000_000_000)
            }
            
            print("All speech examples completed successfully!")
        } catch {
            print("Advanced speech example failed: \(error)")
        }
    }
}

/// Run this from a command-line application
public func runSpeechKitExample() async {
    let example = SpeechKitExample()
    
    print("Running simple speech example...")
    await example.simpleSpeech()
    
    print("\nRunning advanced speech example...")
    await example.advancedSpeech()
}
