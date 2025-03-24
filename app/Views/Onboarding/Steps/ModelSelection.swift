//
//  ModelSelection.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 5/16/25.
//

import SwiftUI
import MLXLMCommon
import Models

struct ModelSelection: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @ObservedObject var appSettings: AppSettings
    @State private var selectedModelDetails: Model?
    
    init(onboardingManager: OnboardingManager = OnboardingManager.shared, appSettings: AppSettings) {
        self.onboardingManager = onboardingManager
        self.appSettings = appSettings
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Image(systemName: "cpu")
                .font(.system(size: 60))
                .foregroundStyle(.primary)
            
            Text("Select Your AI Model")
                .font(.title)
                .fontWeight(.bold)
            
            // Model Selection
            VStack(alignment: .leading, spacing: 16) {
                
                // Table of models instead of dropdown
                VStack(spacing: 8) {
                    HStack {
                        Text("Model")
                            .font(.caption.bold())
                            .frame(width: 200, alignment: .leading)
                        
                        Text("Size")
                            .font(.caption.bold())
                            .frame(width: 80, alignment: .leading)
                        
                        Text("Status")
                            .font(.caption.bold())
                            .frame(width: 120, alignment: .trailing)
                    }
                    .padding(.horizontal, 8)
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(spacing: 8) {
                        ForEach(CoreModels.available.filter { model in
                            return model.name.lowercased().contains("hermes") || 
                                   model.name.lowercased().contains("gemma") || 
                                   model.name.lowercased().contains("mistral")
                        }.prefix(3), id: \.name) { model in
                            ModelRowView(
                                model: model,
                                isSelected: onboardingManager.selectedCoreModel == model.name,
                                isInstalled: appSettings.installedModels.contains(model.name),
                                onSelect: {
                                    onboardingManager.selectedCoreModel = model.name
                                    selectedModelDetails = model
                                }
                            )
                        }
                    }
                    //.frame(height: 100)

                }
            }
            .padding()
            .background(Color(.windowBackgroundColor).opacity(0.3))
            .cornerRadius(8)
            
            // Model Details
            if let model = selectedModelDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Model: \(model.name)")
                        .font(.headline)
                    
                    if let description = model.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label(formatSize(model.size), systemImage: "memorychip")
                        
                        Spacer()
                        
                        if appSettings.installedModels.contains(model.name) {
                            Text("Already downloaded")
                                .font(.caption)
                                .foregroundColor(.primary)
                        } else {
                            Text("Will be downloaded when needed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.windowBackgroundColor).opacity(0.3))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Use the default model as defined in Core.swift if no model is selected
            if onboardingManager.selectedCoreModel.isEmpty {
                onboardingManager.selectedCoreModel = CoreModels.defaultModel
            }
            
            // Initialize the model details when view appears
            selectedModelDetails = ModelRegistry.shared.getModels(for: .core).first { 
                $0.name == onboardingManager.selectedCoreModel 
            }
        }
    }
    
    private func formatSize(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        return String(format: "%.1f GB", gb)
    }
}

/// Individual row in the model table
struct ModelRowView: View {
    let model: Model
    let isSelected: Bool
    let isInstalled: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Model name with selection indicator
                HStack {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Text(model.name)
                }
                .frame(width: 200, alignment: .leading)
                
                // Model size
                Text(formatSize(model.size))
                    .font(.caption)
                    .frame(width: 80, alignment: .leading)
                    .foregroundColor(.secondary)
                
                // Status indicator
                HStack {
                    if isInstalled {
                        Label("Downloaded", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.primary)
                    } else {
                        Text("Not Downloaded")
                            .foregroundColor(.secondary)
                    }
                }
                .font(.caption)
                .frame(width: 120, alignment: .trailing)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatSize(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        return String(format: "%.1f GB", gb)
    }
}

#Preview {
    ModelSelection(appSettings: AppSettings())
        .environmentObject(OnboardingManager.shared)
} 