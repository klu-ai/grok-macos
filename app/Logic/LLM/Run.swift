//
//  Run.swift
//  MLX implementation to run models
//
//  Created by Stephen M. Walker II on 2/19/25.
//
//  Description:
//  This file defines the RunLLM class which manages interactions with LLM and vision models.
//  It handles model loading, switching between models, asynchronous text/vision generation,
//  progress tracking, and cancellation of operations.
//
//  Usage:
//  - Use generate(modelName:thread:systemPrompt:) for text-only generation.
//  - Use vision(prompt:image:videoURL:) for vision-based generation.
//  - Use switchModel(_:) to change the active model (LLM or VLM).
//  - Call stop() to cancel an ongoing generation.
//  - Monitor properties such as output, progress, and stat to update the UI.
//
//  Dependencies:
//  - Requires MLX, MLXLLM, MLXVLM, MLXLMCommon, MLXRandom, and SwiftUI frameworks.
//

import MLX
import MLXLLM
import MLXVLM
import MLXLMCommon
import MLXRandom
import SwiftUI
import CoreGraphics // For CGSize
import Foundation
import Hub

/// Errors related to RunLLM operations.
enum RunLLMError: Error {
    /// Thrown when the specified model cannot be found.
    case modelNotFound(String)
    /// Thrown when model memory requirement exceeds guardrails limit
    case memoryLimitExceeded(String)
    /// Thrown when an invalid parameter is provided to a tool function
    case invalidParameters(String)
    /// Thrown when an unknown function is called
    case unknownFunction(String)
    /// Thrown when too many function calls are made in a single conversation
    case tooManyFunctionCalls
}

/// An observable class that manages the lifecycle and interactions with LLM/vision models.
/// It supports asynchronous text generation, vision-based generation, model switching, and cancellation.
@Observable
@MainActor
class RunLLM: ObservableObject {
    // MARK: - State Properties
    
    var running = false
    var cancelled = false // local flag for UI or external checks
    var output = ""
    var modelInfo = ""
    var stat = ""
    var progress = 0.0
    var thinkingTime: TimeInterval?
    var collapsed: Bool = false
    var isThinking: Bool = false
    
    // active model name
    var activeModelName: String?
    
    // Reference to AppSettings for tracking installed models
    var appSettings: AppSettings?

    /// Returns the elapsed time since the current generation started.
    var elapsedTime: TimeInterval? {
        if let startTime {
            return Date().timeIntervalSince(startTime)
        }
        return nil
    }

    private var startTime: Date?

    var configModel = ModelConfiguration.defaultModel

    // Keep a reference to the active generation task so we can cancel it.
    private var generationTask: Task<MLXLMCommon.GenerateResult, Error>?

    // MARK: - Model Management Methods

    func switchModel(_ model: ModelConfiguration) async {
        activeModelName = model.name.replacingOccurrences(of: "mlx-community/", with: "")
        
        print("Switching to model: \(activeModelName ?? "unknown model")")
        
        progress = 0.0
        loadState = .idle
        configModel = model
        
        do {
            if let modelName = activeModelName {
                _ = try await load(modelName: modelName)
                // Container is loaded but not used here; keeping for potential future use
            } else {
                throw RunLLMError.modelNotFound("Model name is nil")
            }
        } catch {
            print("Error loading model \(activeModelName ?? "unknown model"): \(error)")
        }
        
        activeModelName = nil
    }

    // MARK: - Generation Parameters

    let generateParameters = GenerateParameters(temperature: 0.789)
    let maxTokens = 4096
    let displayEveryNTokens = 4

    // MARK: - Model Loading State

    enum LoadState {
        case idle
        case downloading(String) // Tracks the model being downloaded with name
        case loading(String) // Tracks the model being loaded with name
        case loaded(ModelContainer)
    }

    var loadState = LoadState.idle

    // Add MLXModelLoadingProgress type definition
    struct MLXModelLoadingProgress {
        let fractionCompleted: Double
    }

    // Dictionary to store tool functions
    @ObservationIgnored
    var toolFunctions: [String: Any] = [:]

    init() {
        self.running = false
        self.cancelled = false
        self.output = ""
        self.modelInfo = ""
        self.stat = ""
        self.progress = 0.0
        self.thinkingTime = nil
        self.collapsed = false
        self.isThinking = false
        self.activeModelName = nil
        self.appSettings = nil
        self.startTime = nil
        self.configModel = ModelConfiguration.defaultModel
        self.generationTask = nil
        self.loadState = .idle
    }

    /// Checks if a model is fully downloaded by validating required files
    private func isModelFullyDownloaded(modelName: String, modelConfig: ModelConfiguration) -> Bool {
        let fileManager = FileManager.default
        
        // Get model directory
        let modelDir = modelConfig.modelDirectory()
        
        print("🔍 DEBUG: Checking model files in directory: \(modelDir.path)")
        
        // Check if directory exists
        guard fileManager.fileExists(atPath: modelDir.path) else {
            print("❌ DEBUG: Model directory does not exist: \(modelDir.path)")
            return false
        }
        
        // Check directory contents
        do {
            let dirContents = try fileManager.contentsOfDirectory(atPath: modelDir.path)
            print("📂 DEBUG: Directory contents (\(dirContents.count) files):")
            for file in dirContents.sorted() {
                let filePath = modelDir.appendingPathComponent(file)
                let fileAttributes = try fileManager.attributesOfItem(atPath: filePath.path)
                let fileSize = fileAttributes[.size] as? UInt64 ?? 0
                let fileSizeMB = Double(fileSize) / (1024 * 1024)
                print("  - \(file) (\(String(format: "%.2f", fileSizeMB)) MB)")
            }
        } catch {
            print("⚠️ DEBUG: Error listing directory contents: \(error)")
        }
        
        // Check for model.safetensors.index.json file
        let indexFile = modelDir.appendingPathComponent("model.safetensors.index.json")
        
        guard fileManager.fileExists(atPath: indexFile.path) else {
            print("❌ DEBUG: Index file not found: \(indexFile.path)")
            return false
        }
        
        do {
            // Read and parse the index file to get the list of required model files
            let data = try Data(contentsOf: indexFile)
            print("📊 DEBUG: Successfully read index file: \(indexFile.lastPathComponent)")
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔑 DEBUG: Index file keys: \(json.keys.joined(separator: ", "))")
                
                if let weightMap = json["weight_map"] as? [String: String] {
                    // Get unique safetensors filenames
                    let safetensorsFiles = Set(weightMap.values)
                    
                    print("📋 DEBUG: Weight map contains \(weightMap.count) entries, mapping to \(safetensorsFiles.count) unique files:")
                    
                    // Print sample of weight map (first 5 entries)
                    let sampleKeys = Array(weightMap.keys.prefix(5))
                    for key in sampleKeys {
                        print("  - \"\(key)\" → \"\(weightMap[key] ?? "")\"")
                    }
                    
                    if weightMap.count > 5 {
                        print("  - ... and \(weightMap.count - 5) more entries")
                    }
                    
                    print("🧩 DEBUG: Required unique safetensors files (\(safetensorsFiles.count)):")
                    for file in safetensorsFiles.sorted() {
                        let filePath = modelDir.appendingPathComponent(file)
                        if fileManager.fileExists(atPath: filePath.path) {
                            do {
                                let fileAttributes = try fileManager.attributesOfItem(atPath: filePath.path)
                                let fileSize = fileAttributes[.size] as? UInt64 ?? 0
                                let fileSizeMB = Double(fileSize) / (1024 * 1024)
                                print("  ✅ \(file) (\(String(format: "%.2f", fileSizeMB)) MB)")
                            } catch {
                                print("  ✅ \(file) (size unknown: \(error))")
                            }
                        } else {
                            print("  ❌ \(file) (missing)")
                            return false
                        }
                    }
                    
                    // Additionally check for tokenizer files
                    print("🔤 DEBUG: Checking for additional required files:")
                    let requiredFiles = ["tokenizer.json", "tokenizer_config.json", "special_tokens_map.json"]
                    var allRequiredFilesExist = true
                    
                    for file in requiredFiles {
                        let filePath = modelDir.appendingPathComponent(file)
                        if fileManager.fileExists(atPath: filePath.path) {
                            do {
                                let fileAttributes = try fileManager.attributesOfItem(atPath: filePath.path)
                                let fileSize = fileAttributes[.size] as? UInt64 ?? 0
                                let fileSizeKB = Double(fileSize) / 1024
                                print("  ✅ \(file) (\(String(format: "%.2f", fileSizeKB)) KB)")
                            } catch {
                                print("  ✅ \(file) (size unknown)")
                            }
                        } else {
                            if file == "tokenizer.json" {
                                print("  ❌ \(file) (missing - required)")
                                allRequiredFilesExist = false
                            } else {
                                print("  ⚠️ \(file) (missing - optional)")
                            }
                        }
                    }
                    
                    if !allRequiredFilesExist {
                        return false
                    }
                    
                    // Check for model config file
                    let configFile = modelDir.appendingPathComponent("config.json")
                    if fileManager.fileExists(atPath: configFile.path) {
                        do {
                            let fileAttributes = try fileManager.attributesOfItem(atPath: configFile.path)
                            let fileSize = fileAttributes[.size] as? UInt64 ?? 0
                            let fileSizeKB = Double(fileSize) / 1024
                            print("  ✅ config.json (\(String(format: "%.2f", fileSizeKB)) KB)")
                        } catch {
                            print("  ✅ config.json (size unknown)")
                        }
                    } else {
                        print("  ⚠️ config.json (missing - optional)")
                    }
                    
                    print("✅ DEBUG: All required model files are present")
                    return true
                } else {
                    print("❌ DEBUG: No 'weight_map' found in index file")
                }
            } else {
                print("❌ DEBUG: Failed to parse index file as JSON")
            }
        } catch {
            print("❌ DEBUG: Error checking model files: \(error)")
        }
        
        return false
    }

    // MARK: - Memory Check Logic
    
    /// Checks if the model's memory requirement exceeds the guardrails limit
    func checkMemoryBeforeLoading(modelName: String) async throws {
        print("Starting memory check for model: \(modelName)")
        
        // Ensure we have an AppSettings instance
        if appSettings == nil {
            appSettings = AppSettings()
            print("Created new AppSettings instance")
        }
        
        // Skip memory checks entirely if guardrails are set to "Off"
        if appSettings?.guardrailsLevel == "Off" {
            print("Guardrails are OFF - skipping memory check")
            return
        }
        
        print("Current guardrails level: \(appSettings?.guardrailsLevel ?? "Unknown")")
        
        guard let modelConfig = ModelConfiguration.getModelByName(modelName) else {
            print("ERROR: Model not found: \(modelName)")
            throw RunLLMError.modelNotFound(modelName)
        }
        
        // Get model size in bytes
        var estimatedMemory: UInt64 = 0
        
        if let modelSize = modelConfig.modelSize {
            // Convert from GB to bytes properly
            let gigabytes = modelSize as NSDecimalNumber
            // 1 GB = 1,073,741,824 bytes (2^30)
            estimatedMemory = UInt64(truncating: gigabytes) * 1_073_741_824
            print("Model size in GB: \(gigabytes)")
        } else {
            print("WARNING: No model size defined for \(modelName)")
        }
        
        let maxAllowedMemory = calculateMaxAllowedMemory()
        
        // Add debugging output
        print("Memory Check Debug:")
        print("Model: \(modelName)")
        print("Model Size: \(formatBytes(estimatedMemory))")
        print("Max Allowed Memory: \(formatBytes(maxAllowedMemory))")
        
        if estimatedMemory > maxAllowedMemory {
            print("ERROR: Memory limit exceeded")
            throw RunLLMError.memoryLimitExceeded("Model memory requirement (\(formatBytes(estimatedMemory))) exceeds guardrails limit (\(formatBytes(maxAllowedMemory))).")
        }
        
        print("Memory check passed for model: \(modelName)")
    }
    
    /// Calculates the maximum allowed memory based on the guardrails setting
    private func calculateMaxAllowedMemory() -> UInt64 {
        let totalMemory = getTotalPhysicalMemory()
        let currentlyUsedMemory = getCurrentlyUsedMemory()
        let availableMemory = totalMemory > currentlyUsedMemory ? totalMemory - currentlyUsedMemory : 0
        let utilizationPercentage = getUtilizationPercentage()
        let maxAllowedMemory = UInt64(Double(availableMemory) * (utilizationPercentage / 100.0))
        
        print("Memory Calculation Debug:")
        print("Total Memory: \(formatBytes(totalMemory))")
        print("Currently Used Memory: \(formatBytes(currentlyUsedMemory))")
        print("Available Memory: \(formatBytes(availableMemory))")
        print("Utilization Percentage: \(utilizationPercentage)%")
        print("Max Allowed Memory: \(formatBytes(maxAllowedMemory))")
        
        return maxAllowedMemory
    }
    
    /// Retrieves the utilization percentage based on the guardrails level
    private func getUtilizationPercentage() -> Double {
        // Ensure we have an AppSettings instance
        if appSettings == nil {
            appSettings = AppSettings()
        }
        
        switch appSettings?.guardrailsLevel {
        case "Off": return 100.0
        case "Relaxed": return 80.0
        case "Balanced": return 60.0
        case "Strict": return 40.0
        case "Custom": return appSettings?.customMemoryUtilization ?? 50.0
        default: return 60.0 // Default to Balanced
        }
    }
    
    /// Gets the total physical memory of the system
    private func getTotalPhysicalMemory() -> UInt64 {
        var size = MemoryLayout<UInt64>.size
        var totalMemory: UInt64 = 0
        sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0)
        return totalMemory
    }
    
    /// Gets the currently used system memory
    private func getCurrentlyUsedMemory() -> UInt64 {
        let hostPort = mach_host_self()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var hostInfo = vm_statistics64_data_t()
        
        let pageSize = getPageSize()
        
        let result = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }
        
        if result == KERN_SUCCESS {
            // Calculate used memory (consider only wired memory as truly "used")
            let wiredMemory = UInt64(hostInfo.wire_count) * pageSize
            
            // Include compressed memory if available
            let compressedMemory = UInt64(hostInfo.compressor_page_count) * pageSize
            
            // For debugging, we'll calculate what the old method would have done
            let activeMemory = UInt64(hostInfo.active_count) * pageSize
            let oldCalculation = wiredMemory + activeMemory
            
            // New calculation only includes wired + compressed memory
            let usedMemory = wiredMemory + compressedMemory
            
            // Debugging output
            print("Memory Usage Details:")
            print("Wired Memory: \(formatBytes(wiredMemory))")
            print("Compressed Memory: \(formatBytes(compressedMemory))")
            print("Active Memory (not used in calculation): \(formatBytes(activeMemory))")
            print("Old Calculation (wired+active): \(formatBytes(oldCalculation))")
            print("New Calculation (wired+compressed): \(formatBytes(usedMemory))")
            
            return usedMemory
        }
        
        // Fallback - if we can't get actual used memory, assume 25% is in use
        let fallbackMemory = getTotalPhysicalMemory() / 4
        print("Failed to get memory statistics, using fallback of 25%: \(formatBytes(fallbackMemory))")
        return fallbackMemory
    }
    
    /// Gets the system page size
    private func getPageSize() -> UInt64 {
        var pageSize64: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.pagesize", &pageSize64, &size, nil, 0)
        return pageSize64
    }
    
    /// Formats bytes into a human-readable string
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// Loads and returns the model container corresponding to the given model name.
    /// - Parameter modelName: The name of the model to load (e.g. "pixtral_12b_4bit" for vision).
    /// - Throws: A RunLLMError.modelNotFound error if the model cannot be located.
    /// - Returns: A ModelContainer instance representing the loaded model.
    func load(modelName: String) async throws -> ModelContainer {
        // Check memory guardrails before loading
        try await checkMemoryBeforeLoading(modelName: modelName)
        
        guard let modelConfig = ModelConfiguration.getModelByName(modelName) else {
            throw RunLLMError.modelNotFound(modelName)
        }

        switch loadState {
        case .idle:
            // Check if the model is fully downloaded
            let isFullyDownloaded = isModelFullyDownloaded(modelName: modelName, modelConfig: modelConfig)
            
            // Set the appropriate state based on download status
            if isFullyDownloaded {
                loadState = .loading(modelName)
                modelInfo = "Loading \(modelName)..."
            } else {
                loadState = .downloading(modelName)
                modelInfo = "Downloading \(modelName)..."
            }

            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
            
            // Print the model directory
            // Used for debugging model loading issues
            let modelDir = modelConfig.modelDirectory()
            print("Model is saved at: \(modelDir.path)")

            // Load the model using the appropriate factory
            let context = try await {
                if modelConfig.modelType == .vision {
                    return try await VLMModelFactory.shared.load(configuration: modelConfig) { progress in
                        Task { @MainActor in
                            if case .downloading = self.loadState {
                                self.modelInfo = "Downloading \(modelConfig.name): \(Int(progress.fractionCompleted * 100))%"
                            } else {
                                self.modelInfo = "Loading \(modelConfig.name): \(Int(progress.fractionCompleted * 100))%"
                            }
                            self.progress = progress.fractionCompleted
                        }
                    }
                } else {
                    return try await LLMModelFactory.shared.load(configuration: modelConfig) { progress in
                        Task { @MainActor in
                            if case .downloading = self.loadState {
                                self.modelInfo = "Downloading \(modelConfig.name): \(Int(progress.fractionCompleted * 100))%"
                            } else {
                                self.modelInfo = "Loading \(modelConfig.name): \(Int(progress.fractionCompleted * 100))%"
                            }
                            self.progress = progress.fractionCompleted
                        }
                    }
                }
            }()
            
            let container = ModelContainer(context: context)
            let usageMB = MLX.GPU.activeMemory / 1024 / 1024
            modelInfo = "Loaded \(modelConfig.id). Weights: \(usageMB)M"
            
            // Mark model as installed when successfully loaded
            Task { @MainActor in
                appSettings?.addInstalledModel(modelName)
            }
            
            loadState = .loaded(container)
            return container
            
        case .downloading, .loading:
            throw RunLLMError.modelNotFound(modelName)
            
        case .loaded(let modelContainer):
            return modelContainer
        }
    }

    /// Downloads a model without loading it into memory.
    /// - Parameter modelName: The name of the model to download (e.g., "gemma-2-2b-it-4bit").
    /// - Throws: RunLLMError if the model cannot be found or if the download fails.
    func downloadModel(modelName: String) async throws {
        guard let modelConfig = ModelConfiguration.getModelByName(modelName) else {
            throw RunLLMError.modelNotFound(modelName)
        }
        
        // Check memory guardrails before downloading
        // no need to check memory before downloading
        // try await checkMemoryBeforeLoading(modelName: modelName)
        
        activeModelName = modelName
        loadState = .downloading(modelName)
        modelInfo = "Downloading \(modelName)..."
        progress = 0.0
        
        do {
            // Check if model is already downloaded
            if isModelFullyDownloaded(modelName: modelName, modelConfig: modelConfig) {
                print("Model \(modelName) is already downloaded")
                appSettings?.addInstalledModel(modelName)
                loadState = .idle
                modelInfo = "Model \(modelName) is already downloaded"
                return
            }
            
            // Create model directory if it doesn't exist
            let modelDir = modelConfig.modelDirectory()
            try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
            
            // Download the model
            let hub = HubApi()
            _ = try await MLXLMCommon.downloadModel(hub: hub, configuration: modelConfig) { progress in
                Task { @MainActor in
                    self.modelInfo = "Downloading \(modelConfig.name): \(Int(progress.fractionCompleted * 100))%"
                    self.progress = progress.fractionCompleted
                }
            }
            
            // Verify the download was successful
            if isModelFullyDownloaded(modelName: modelName, modelConfig: modelConfig) {
                appSettings?.addInstalledModel(modelName)
                loadState = .idle
                modelInfo = "Download completed for \(modelName)"
            } else {
                throw RunLLMError.modelNotFound("Model files are incomplete after download")
            }
        } catch {
            loadState = .idle
            modelInfo = "Failed to download \(modelName): \(error.localizedDescription)"
            throw error
        }
        
        // Clear active model name since we're not loading it
        activeModelName = nil
    }

    // MARK: - Generation Control Methods

    /// Cancels an ongoing generation by setting a local flag and cancelling the task.
    func stop() {
        isThinking = false
        cancelled = true
        generationTask?.cancel()
    }

    /// Structured result of the generation process, separating initial output, tool messages, and final output.
    struct GenerateResult {
        let initialOutput: String
        let toolMessages: [[String: String]]
        let finalOutput: String
    }

    /// Generates text asynchronously using the specified model, thread context, and system prompt.
    /// Returns a structured result with initial output, tool messages, and final response.
    /// - Parameters:
    ///   - modelName: The name of the model to use.
    ///   - thread: The conversation thread providing prompt history.
    ///   - systemPrompt: The system-level prompt to augment generation.
    /// - Returns: A GenerateResult containing the generation components.
    func generate(modelName: String, thread: Thread, systemPrompt: String) async -> String {
        guard !running else { return "" }
        running = true
        cancelled = false
        output = ""
        startTime = Date()
        
        defer {
            running = false
            isThinking = false
            if let startTime = startTime {
                thinkingTime = Date().timeIntervalSince(startTime)
            }
        }
        
        do {
            let modelContainer = try await load(modelName: modelName)
            let currentMessages = modelContainer.configuration.getPromptHistory(
                thread: thread,
                systemPrompt: systemPrompt
            )
            
            print("isThinking: \(isThinking)")
            if modelContainer.configuration.modelType == .reasoning || modelContainer.configuration.modelType == .regular {
                isThinking = true
            }
            print("isThinking: \(isThinking)")

            // Generate text
            print("Starting text generation")
            let generatedOutput = try await generateText(modelContainer: modelContainer, messages: currentMessages)
            print("Model output: \(generatedOutput)")
            output = generatedOutput
            
            return generatedOutput
            
        } catch {
            let errorMessage = "Generation failed: \(error.localizedDescription)"
            print(errorMessage)
            output = errorMessage
            return errorMessage
        }
    }
    
    // MARK: - Vision Generation
    
    /// Generates output using a vision-capable model by combining a text prompt with an optional image or video.
    /// Uses the pixtral_12b_4bit model for image/video comprehension.
    ///
    /// - Parameters:
    ///   - prompt: The text prompt to guide generation.
    ///   - image: An optional CIImage to provide visual context.
    ///   - videoURL: An optional URL to a video file for visual context.
    func vision(prompt: String, image: CIImage? = nil, videoURL: URL? = nil) async {
        guard !running else { return }
        running = true
        cancelled = false
        output = ""
        startTime = Date()
        
        defer {
            running = false
            isThinking = false
        }
        
        do {
            let modelContainer = try await load(modelName: VisionModels.defaultModel)
            
            if modelContainer.configuration.modelType == ModelConfiguration.ModelType.vision {
                isThinking = true
            }
            
            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))
            
            // Convert image and videoURL to [UserInput.Image]
            let imageObjects: [UserInput.Image] = {
                var imgs = [UserInput.Image]()
                if let img = image {
                    imgs.append(.ciImage(img))
                }
                if let videoURL = videoURL {
                    imgs.append(.url(videoURL))
                }
                return imgs
            }()
            
            // Define processing (adjust size as needed based on your model)
            let processing = UserInput.Processing(resize: CGSize(width: 448, height: 448))
            
            // Create UserInput with text prompt and images
            let userInput = UserInput(prompt: .text(prompt), images: imageObjects, processing: processing)
            
            // Create a local copy to avoid Swift 6 concurrency capture issues
            let localUserInput = userInput
            
            generationTask = Task {
                let result = try await modelContainer.perform { context in
                    let input = try await context.processor.prepare(input: localUserInput)
                    var lastTokenCount = 0
                    
                    return try MLXLMCommon.generate(
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
                }
                
                if result.output != self.output {
                    self.output = result.output
                }
                self.stat = " Tokens/second: \(String(format: "%.3f", result.tokensPerSecond))"
                return result
            }
            
            _ = try await generationTask!.value
        } catch {
            output = "Failed: \(error)"
        }
    }

    // MARK: - Tool Implementation Methods
    
    // The implementation of tool methods has been moved to FunctionCalls.swift
    // This includes:
    // - transcribeAudio(audioPath:)
    // - analyzeImage(imagePath:)
    // - performReasoning(problem:)
    // - extractToolCalls(from:)
    // - ToolCall struct definition
    // - executeTool(_:)
    // - generateText(modelContainer:messages:)
}

extension RunLLM.LoadState {
    var isLoading: Bool {
        switch self {
        case .loading, .downloading:
            return true
        default:
            return false
        }
    }
    
    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }
    
    var isDownloading: Bool {
        switch self {
        case .downloading:
            return true
        default:
            return false
        }
    }
}
