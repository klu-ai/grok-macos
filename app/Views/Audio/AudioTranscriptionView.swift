import SwiftUI
import AudioKit
import AVFoundation

/// A view that provides two ways to transcribe audio:
/// 1) From microphone in real-time (showing a waveform)
/// 2) From a selected audio file
struct AudioTranscriptionView: View {
    @StateObject private var manager = WhisperTranscriptionManager.shared
    
    // Audio recording state
    @State private var isRecording: Bool = false
    @State private var audioProcessor: AudioProcessor? = nil
    @State private var waveformSamples: [Float] = []
    @State private var transcriptionResult: String = ""
    @State private var isLoadingWhisperModel: Bool = false
    
    // For file-based transcription
    @State private var showFileImporter: Bool = false
    
    // For permission handling
    @State private var showPermissionAlert: Bool = false
    
    // For error alert
    @State private var showErrorAlert: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Audio Transcription")
                .font(.title2)
                .bold()
            
            if manager.isDownloadingModel {
                ProgressView(value: manager.modelDownloadProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 10)
            } else {
                Text(manager.status)
                    .foregroundColor(.secondary)
            }
            
            // SECTION 1: Microphone transcription
            Text("Microphone Recording")
                .font(.headline)
            
            HStack {
                Button(action: {
                    Task {
                        print("Recording button pressed, isRecording: \(isRecording)")
                        
                        // Load the model if not loaded yet
                        if !manager.isModelLoaded && !manager.isDownloadingModel {
                            isLoadingWhisperModel = true
                            await manager.loadWhisperModel()
                            isLoadingWhisperModel = false
                        }
                        
                        if isRecording {
                            // Stop recording
                            stopRecording()
                        } else {
                            // Start recording
                            await startRecording()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: getRecordingButtonIcon())
                        Text(isRecording ? "Stop Microphone" : "Start Microphone")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isDownloadingModel || isLoadingWhisperModel)
                
                Spacer()
                
                WaveformView(samples: waveformSamples)
                    .frame(height: 40)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.trailing, 16)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // SECTION 2: File-based transcription
            Text("File-based Transcription")
                .font(.headline)
            
            Button("Select Audio File for Transcription") {
                showFileImporter.toggle()
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // SECTION 3: Transcription results
            if !transcriptionResult.isEmpty {
                Text("Transcription Result:")
                    .font(.headline)
                ScrollView {
                    Text(transcriptionResult)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.textBackgroundColor).opacity(0.2))
                        .cornerRadius(8)
                }
                .frame(height: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                if !manager.isModelLoaded && !manager.isDownloadingModel {
                    isLoadingWhisperModel = true
                    await manager.loadWhisperModel()
                    isLoadingWhisperModel = false
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let url):
                Task {
                    let text = await transcribeFile(url: url)
                    self.transcriptionResult = text
                }
            case .failure(let error):
                manager.errorMessage = "File import failed: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        // Alert for permission errors
        .alert("Permission Error", isPresented: $showPermissionAlert) {
            Button("OK") {
                showPermissionAlert = false
            }
        } message: {
            Text("Unable to access microphone. Please ensure that microphone access is enabled in System Preferences > Privacy & Security > Microphone.")
        }
        // Alert for general errors
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                showErrorAlert = false
                manager.errorMessage = nil
            }
        } message: {
            Text(manager.errorMessage ?? "An error occurred")
        }
    }
    
    private func getRecordingButtonIcon() -> String {
        // Show hourglass when model is downloading or loading
        if (manager.isDownloadingModel || isLoadingWhisperModel) && !isRecording {
            return "hourglass.circle"
        } else if isRecording {
            return "stop.circle.fill"
        } else {
            return "mic.circle.fill"
        }
    }
    
    private func startRecording() async {
        print("Starting recording...")
        
        // Check microphone permission
        let permission = await AudioProcessor.requestRecordPermission()
        if !permission {
            print("Microphone permission denied")
            showPermissionAlert = true
            return
        }
        
        // Create and configure audio processor
        let processor = AudioProcessor()
        do {
            // First set our state variable to retain the processor
            audioProcessor = processor
            
            // Start recording with waveform visualization
            try processor.startRecordingLive(inputDeviceID: nil) { (chunk: [Float]) in
                let segmentSize = 160 // 10ms at 16kHz
                let numSegments = chunk.count / segmentSize
                DispatchQueue.main.async {
                    for i in 0..<numSegments {
                        let start = i * segmentSize
                        let end = min(start + segmentSize, chunk.count)
                        let segment = Array(chunk[start..<end])
                        if !segment.isEmpty {
                            let rms = sqrt(segment.map { $0 * $0 }.reduce(0, +) / Float(segment.count))
                            self.waveformSamples.append(rms)
                        }
                    }
                    if self.waveformSamples.count > 300 {
                        self.waveformSamples.removeFirst(self.waveformSamples.count - 300)
                    }
                }
            }
            
            // Mark as recording (do this AFTER successful start)
            isRecording = true
            print("Recording started successfully")
            
        } catch {
            print("Error starting recording: \(error)")
            // Clean up on error
            audioProcessor = nil
            manager.errorMessage = "Failed to start recording: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func stopRecording() {
        print("Stopping recording...")
        
        // Stop the recording
        audioProcessor?.stopRecording()
        
        // Get the audio samples
        guard let processor = audioProcessor, !processor.audioSamples.isEmpty else {
            print("No audio processor or audio samples available")
            isRecording = false
            return
        }
        
        let samples = Array(processor.audioSamples)
        print("Stopped recording with \(samples.count) samples")
        // Debug audio samples
        if !samples.isEmpty {
            let maxVal = samples.map { abs($0) }.max() ?? 0
            let minVal = samples.map { abs($0) }.min() ?? 0
            let avgVal = samples.map { abs($0) }.reduce(0, +) / Float(samples.count)
            print("Sample stats - Max: \(maxVal), Min: \(minVal), Avg: \(avgVal)")
        }
        
        // Reset the local buffer
        processor.purgeAudioSamples(keepingLast: 0)
        
        // Update state to indicate we're not recording
        isRecording = false
        
        // Transcribe the recorded audio
        Task {
            let recognized = await manager.transcribeAudioData(samples.map { Float($0) })
            print("Transcription result: \(recognized)")
            transcriptionResult = recognized
            
            // Now it's safe to nil the processor
            audioProcessor = nil
        }
    }
    
    private func transcribeFile(url: URL) async -> String {
        do {
            // Read the audio file data
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = UInt32(audioFile.length)
            
            // Create a buffer to hold the audio data
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
            try audioFile.read(into: buffer!)
            
            var audioData: [Float] = []
            
            // Convert the buffer to a Float array for the transcription model
            if let channelData = buffer?.floatChannelData?[0] {
                let count = Int(buffer!.frameLength)
                audioData = Array(UnsafeBufferPointer(start: channelData, count: count))
            }
            
            // If data was successfully extracted, transcribe it
            if !audioData.isEmpty {
                return await manager.transcribeAudioData(audioData)
            } else {
                manager.errorMessage = "Could not extract audio data from file"
                showErrorAlert = true
                return "Error: Could not extract audio data"
            }
        } catch {
            manager.errorMessage = "Error processing audio file: \(error.localizedDescription)"
            showErrorAlert = true
            return "Error: \(error.localizedDescription)"
        }
    }
}

/// Improved waveform view that draws a centered waveform with proper scaling
struct WaveformView: View {
    let samples: [Float]
    
    var body: some View {
        GeometryReader { geo in
            if let maxRms = samples.max(), maxRms > 0 {
                let scale = geo.size.height / CGFloat(maxRms)
                let barWidth = max(geo.size.width / CGFloat(samples.count), 0.5)
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(samples.indices, id: \.self) { idx in
                        let rms = samples[idx]
                        let barHeight = CGFloat(rms) * scale
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: barWidth, height: barHeight)
                    }
                }
                .frame(height: geo.size.height)
            } else {
                Text("No audio data")
                    .foregroundColor(.gray)
                    .hidden()
            }
        }
    }
}