//
//  ModelsPreferences.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages API configuration and model preferences for the Grok assistant.
//  Provides an interface for configuring API settings and model parameters.
//
//  Key features:
//  - API configuration (endpoint and key)
//  - Model parameter settings
//  - Runtime environment configuration
//
//  Implementation notes:
//  - Uses AppStorage for persistent preferences
//  - Implements secure storage for API keys
//  - Provides model configuration options
//
//  Dependencies:
//  - SwiftUI: UI framework
//  - Foundation: Core functionality
//
//  Usage:
//  - Configure API settings
//  - Set model parameters
//  - View and modify runtime settings

import SwiftUI

struct ModelsPreferences: View {
    @EnvironmentObject var appSettings: AppSettings
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("apiEndpoint") private var apiEndpoint: String = "https://api.example.com"
    @AppStorage("selectedModel") private var selectedModel: String = "grok-3"
    @AppStorage("temperature") private var temperature: Double = 0.7
    @AppStorage("maxTokens") private var maxTokens: Int = 4096
    
    var body: some View {
        Form {
            Section("API Configuration") {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                TextField("API Endpoint", text: $apiEndpoint)
                    .textFieldStyle(.roundedBorder)
            }
            
            Section("Model Settings") {
                Picker("Model", selection: $selectedModel) {
                    Text("Grok-3").tag("grok-3")
                    Text("Grok-2").tag("grok-2")
                    Text("Grok-1").tag("grok-1")
                }
                
                VStack(alignment: .leading) {
                    Text("Temperature: \(String(format: "%.1f", temperature))")
                    Slider(value: $temperature, in: 0...2, step: 0.1)
                }
                
                Stepper("Max Tokens: \(maxTokens)", value: $maxTokens, in: 1...8192, step: 256)
            }
            
            Section {
                Text("Using API-based model inference")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    ModelsPreferences()
        .environmentObject(AppSettings())
}

// MARK: - Model Type List View
struct ModelTypeListView: View {
    let models: [Model]
    @Binding var installedModels: [String]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(models) { model in
                ModelItemView(
                    model: model,
                    isInstalled: installedModels.contains(model.name)
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        //.background(Color.secondary.opacity(0.05))
        //.cornerRadius(8)
    }
}

// MARK: - Model Item View
struct ModelItemView: View {
    let model: Model
    let isInstalled: Bool
    
    @EnvironmentObject var runLLM: RunLLM
    @State private var smoothedProgress: Double = 0.0
    @State private var lastProgress: Double = 0.0
    @State private var downloadStartTime: Date? = nil
    @State private var estimatedTimeRemaining: TimeInterval? = nil
    @State private var lastProgressUpdateTime: Date? = nil
    @State private var downloadSpeed: Double = 0.0 // bytes per second
    
    var isActive: Bool {
        runLLM.activeModelName == model.name
    }
    
    var isDownloading: Bool {
        runLLM.activeModelName == model.name && (runLLM.loadState.isDownloading || runLLM.loadState.isLoading)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            HStack {
                Text(model.lab)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                Text(model.displayName)
                    .font(.caption)
            }
            
            if isDownloading {
                // Download progress view with enhanced layout
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Use the stored smoothedProgress instead of calculating it
                        let displayProgress = smoothedProgress
                        let downloadedSize = Double(model.size) * displayProgress
                        let totalSize = Double(model.size)
                        let percentComplete = Int(displayProgress * 100)
                        
                        Text("\(percentComplete)% • \(formatBytes(downloadedSize)) of \(formatBytes(totalSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Full-width progress bar
                    if runLLM.loadState.isDownloading {
                        ProgressView(value: smoothedProgress, total: 1)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: .infinity)
                        
                        Text("Downloading \(estimatedTimeRemainingText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if runLLM.loadState.isLoading {
                        ProgressView(value: smoothedProgress, total: 1)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: .infinity)
                        
                        Text("Loading model")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .onChange(of: runLLM.progress) { oldValue, newValue in
                    // Only update progress if it's increasing or if we're in a new downloading phase
                    if newValue >= lastProgress || newValue < 0.05 {
                        if downloadStartTime == nil {
                            downloadStartTime = Date()
                            lastProgressUpdateTime = Date()
                        } else if let lastTime = lastProgressUpdateTime {
                            // Update download speed and estimated time
                            let now = Date()
                            let elapsedTime = now.timeIntervalSince(lastTime)
                            if elapsedTime > 0.5 { // Only update every 0.5 seconds to smooth fluctuations
                                let progressDelta = newValue - lastProgress
                                let bytesDelta = Double(model.size) * progressDelta
                                
                                // Calculate current download speed (bytes per second)
                                if elapsedTime > 0 && bytesDelta > 0 {
                                    let currentSpeed = bytesDelta / elapsedTime
                                    // Smooth speed calculation with moving average
                                    downloadSpeed = downloadSpeed == 0 ? currentSpeed : (downloadSpeed * 0.7 + currentSpeed * 0.3)
                                
                                    // Calculate remaining time
                                    let remainingBytes = Double(model.size) * (1.0 - newValue)
                                    if downloadSpeed > 0 {
                                        estimatedTimeRemaining = remainingBytes / downloadSpeed
                                    }
                                }
                                lastProgressUpdateTime = now
                            }
                        }
                        
                        lastProgress = newValue
                        updateSmoothedProgress(newValue)
                    }
                }
                .onAppear {
                    // Reset on appear
                    downloadStartTime = nil
                    estimatedTimeRemaining = nil
                    lastProgressUpdateTime = nil
                    downloadSpeed = 0.0
                }
            } else {
                // Spacing element to push the size and action button to the right
                Spacer()
                
                // Model size
                Text(formattedSize(for: model))
                    .font(.caption)
                    //.frame(width: 80, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                
                // Model status or action
                Group {
                    if isActive && runLLM.loadState.isLoaded {
                        Text("Loaded")
                            .font(.caption)
                            .frame(width: 120)
                    } else if isInstalled {
                        ManageModelButton(modelName: model.name)
                    } else {
                        DownloadModelButton(model: model)
                    }
                }
                // Reset progress tracking when not downloading
                .onAppear {
                    smoothedProgress = 0.0
                    lastProgress = 0.0
                    downloadStartTime = nil
                    estimatedTimeRemaining = nil
                    lastProgressUpdateTime = nil
                    downloadSpeed = 0.0
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Format the estimated time remaining in a human-readable format
    private var estimatedTimeRemainingText: String {
        guard let timeRemaining = estimatedTimeRemaining, timeRemaining.isFinite, !timeRemaining.isNaN, timeRemaining > 0 else {
            return ""
        }
        
        if timeRemaining < 60 {
            return "(~\(Int(ceil(timeRemaining)))s remaining)"
        } else if timeRemaining < 3600 {
            let minutes = Int(ceil(timeRemaining / 60))
            return "(~\(minutes)m remaining)"
        } else {
            let hours = Int(ceil(timeRemaining / 3600))
            let minutes = Int(ceil((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60))
            return "(~\(hours)h \(minutes)m remaining)"
        }
    }
    
    // Calculate a smoothed progress value without modifying state
    private func calculateSmoothedProgress(_ newProgress: Double) -> Double {
        // Smoothing factor (0.3 gives a good balance between responsiveness and smoothness)
        let alpha: Double = 0.3
        
        // Never allow progress to decrease during active downloading
        if newProgress < smoothedProgress && newProgress > 0.05 {
            return smoothedProgress
        }
        
        // Apply exponential smoothing
        let result = (alpha * newProgress) + ((1.0 - alpha) * smoothedProgress)
        
        // Ensure progress doesn't exceed 100%
        return min(result, 1.0)
    }
    
    // Update the smoothed progress state (call this only from non-view contexts)
    private func updateSmoothedProgress(_ newProgress: Double) {
        smoothedProgress = calculateSmoothedProgress(newProgress)
    }
    
    // Previously named smoothProgress - now deprecated and replaced with the two functions above
    // Kept for backward compatibility if needed
    @available(*, deprecated, message: "Use calculateSmoothedProgress or updateSmoothedProgress instead")
    private func smoothProgress(_ newProgress: Double) -> Double {
        // This function is no longer used directly
        return 0.0
    }
    
    private func formattedSize(for model: Model) -> String {
        let gb = Double(model.size) / (1024 * 1024 * 1024)
        return String(format: "%.1f GB", gb)
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Manage Model Button
struct ManageModelButton: View {
    let modelName: String
    
    var body: some View {
        Button("Manage") {
            if let modelConfig = ModelConfiguration.getModelByName(modelName) {
                let modelDir = modelConfig.modelDirectory()
                if FileManager.default.fileExists(atPath: modelDir.path) {
                    NSWorkspace.shared.open(modelDir)
                } else {
                    print("Model directory does not exist: \(modelDir.path)")
                }
            } else {
                print("Could not find model configuration for: \(modelName)")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .frame(width: 120, alignment: .trailing)
    }
}

// MARK: - Download Model Button
struct DownloadModelButton: View {
    let model: Model
    @EnvironmentObject var runLLM: RunLLM
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    var body: some View {
        Button("Download") {
            Task {
                do {
                    try await runLLM.downloadModel(modelName: model.name)
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                    print("Error downloading model: \(error)")
                }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .frame(width: 120, alignment: .trailing)
        .alert("Download Error", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK") {
                showError = false
            }
        } message: { message in
            Text(message)
        }
    }
}

// MARK: - Model Picker View
struct ModelPickerView: View {
    let models: [Model]
    @Binding var selectedModel: String
    
    var body: some View {
        HStack {
            if let selectedModel = models.first(where: { $0.name == selectedModel }) {
                HStack {
                    Text(selectedModel.lab)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    Text("\(selectedModel.displayName) (\(ByteCountFormatter.string(fromByteCount: Int64(selectedModel.size), countStyle: .file)))")
                        .font(.caption)
                }
                Spacer()
            }
            
            Picker("", selection: $selectedModel) {
                ForEach(models) { model in
                    Text(model.displayName)
                        .tag(model.name)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
