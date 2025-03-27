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

// Define the Model struct to fix the "Cannot find type 'Model'" errors
struct Model: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let lab: String
    let size: Int
    
    // Convenience initializer with a default size
    init(name: String, displayName: String, lab: String, size: Int = 0) {
        self.name = name
        self.displayName = displayName
        self.lab = lab
        self.size = size
    }
}

struct ModelsPreferences: View {
    @EnvironmentObject var appSettings: AppSettings
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("apiEndpoint") private var apiEndpoint: String = "https://api.example.com"
    @AppStorage("selectedModel") private var selectedModel: String = "grok-3"
    @AppStorage("temperature") private var temperature: Double = 0.7
    @AppStorage("maxTokens") private var maxTokens: Int = 4096
    
    // Define the models array to use throughout the view
    private let models: [Model] = [
        Model(name: "grok-3", displayName: "Grok-3", lab: "LLM"),
        Model(name: "grok-2", displayName: "Grok-2", lab: "LLM"),
        Model(name: "grok-1", displayName: "Grok-1", lab: "LLM")
    ]
    
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
                    ForEach(models) { model in
                        Text(model.displayName).tag(model.name)
                    }
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
            
        }
        .padding(.vertical, 4)
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
