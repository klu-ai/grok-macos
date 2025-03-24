import AVFoundation
import CoreML
import WhisperKit
import Foundation

public struct AudioDevice {
    let id: String
    let name: String
}

@available(macOS 13, iOS 16, watchOS 10, visionOS 1, *)
public class AudioProcessor: NSObject, AudioProcessing {
    public var audioEngine: AVAudioEngine?
    public var audioSamples = ContiguousArray<Float>()
    private let audioSamplesLock = NSLock()
    public var audioEnergy: [(rel: Float, avg: Float, max: Float, min: Float)] = []
    public var relativeEnergyWindow: Int = 60
    public var minBufferLength: Int = 16000
    public var audioBufferCallback: (([Float]) -> Void)?
    private var converter: AVAudioConverter?
    private let desiredFormat: AVAudioFormat = {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false) else {
            fatalError("Failed to create desired format")
        }
        return format
    }()
    
    /// A measure of current buffer's energy in dB normalized from 0 - 1
    public var relativeEnergy: [Float] {
        let energies = audioEnergy.map { $0.avg }
        guard !energies.isEmpty else { return [] }
        let minVal = energies.min() ?? 0
        let maxVal = energies.max() ?? 1
        return energies.map { ($0 - minVal) / max(0.000001, maxVal - minVal) }
    }

    public override init() {
        super.init()
    }

    /// Load audio from file as needed (unused in this minimal example)
    public static func loadAudio(fromPath audioFilePath: String, startTime: Double?, endTime: Double?, maxReadFrameSize: AVAudioFrameCount?) throws -> AVAudioPCMBuffer {
        throw WhisperError.audioProcessingFailed("Not implemented here")
    }

    /// Load multiple paths
    public static func loadAudio(at audioPaths: [String]) async -> [Result<[Float], any Error>] {
        return audioPaths.map { _ in .failure(WhisperError.audioProcessingFailed("Not implemented here")) }
    }

    /// Resample / read from array
    public static func padOrTrimAudio(fromArray audioArray: [Float], startAt startIndex: Int, toLength frameLength: Int, saveSegment: Bool) -> MLMultiArray? {
        return nil
    }

    /// Start capturing from mic
    public func startRecordingLive(inputDeviceID: String?, callback: (([Float]) -> Void)?) throws {
        audioSamples.removeAll()
        audioBufferCallback = callback
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "AudioProcessor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAudioEngine"])
        }
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        print("Input hardware format: \(inputFormat)")
        print("Desired format: \(desiredFormat)")
        
        // Create a converter once
        converter = AVAudioConverter(from: inputFormat, to: desiredFormat)
        guard let converter = converter else {
            throw NSError(domain: "AudioProcessor", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"])
        }
        
        // Install tap with hardware format
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            guard let self = self else { return }
            
            // Create a buffer for the converted audio
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: self.desiredFormat, 
                                                        frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * self.desiredFormat.sampleRate / buffer.format.sampleRate)) else {
                print("Failed to create conversion buffer")
                return
            }
            
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            // Perform the conversion
            converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            
            if let error = error {
                print("Conversion error: \(error)")
                return
            }
            
            guard let channelData = convertedBuffer.floatChannelData?[0] else {
                print("No channel data in converted buffer")
                return
            }
            
            let frameCount = Int(convertedBuffer.frameLength)
            
            // Safely add samples to our collection
            self.audioSamplesLock.lock()
            for i in 0..<frameCount {
                self.audioSamples.append(channelData[i])
            }
            self.audioSamplesLock.unlock()
            
            print("Added \(frameCount) frames to samples, total now: \(self.audioSamples.count)")
            
            // Call the callback on the main thread
            DispatchQueue.main.async {
                callback?(Array(self.audioSamples))
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("Audio engine started successfully")
        } catch {
            print("AVAudioEngine failed to start: \(error)")
            throw error
        }
    }

    public func pauseRecording() {
        audioEngine?.pause()
    }

    public func stopRecording() {
        print("Stopping audio recording, total samples: \(audioSamples.count)")
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
    }

    public func resumeRecordingLive(inputDeviceID: String?, callback: (([Float]) -> Void)?) throws {
        try startRecordingLive(inputDeviceID: inputDeviceID, callback: callback)
    }

    public func purgeAudioSamples(keepingLast keep: Int) {
        if keep <= audioSamples.count {
            audioSamples.removeFirst(audioSamples.count - keep)
        }
    }

    public static func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    public static func getAudioDevices() -> [AudioDevice] {
        return []
    }

    public static func isVoiceDetected(in relativeEnergy: [Float],
                                       nextBufferInSeconds: Float,
                                       silenceThreshold: Float) -> Bool {
        guard !relativeEnergy.isEmpty else { return false }
        let avg = relativeEnergy.reduce(0, +) / Float(relativeEnergy.count)
        return avg > silenceThreshold
    }
}