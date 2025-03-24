//
//  Onboarding.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Main onboarding coordinator view that manages the step-by-step introduction
//  to the application. Implements a guided setup process with multiple steps
//  to configure essential settings and permissions.
//
//  Key features:
//  - Multi-step onboarding flow
//  - Progress tracking
//  - Permission management
//  - UI tour integration
//
//  Onboarding steps:
//  1. Welcome: Initial greeting and overview
//  2. Model Selection: Choose a model
//  3. Permissions: System access setup
//  4. Preferences: Basic app configuration
//  5. Finished: Completion and next steps
//
//  Implementation notes:
//  - Uses TabView for step navigation
//  - Manages step completion state
//  - Handles permission requests
//  - Saves preferences
//
//  Dependencies:
//  - OnboardingManager: State management
//  - Individual step views
//  - System permission APIs
//
//  Usage:
//  - Shown on first launch
//  - Can be reset via preferences
//  - Handles interrupted setup
//  - Saves progress between steps
//

import SwiftUI
import MLXLMCommon
import Models

/// The main container view for the onboarding process.
struct Onboarding: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var runLLM: RunLLM
    
    var body: some View {
        VStack(spacing: 0) {
            // Current step view
            Group {
                switch onboardingManager.currentStep {
                case .welcome:
                    Welcome()
                case .modelSelection:
                    ModelSelection(onboardingManager: onboardingManager, appSettings: appSettings)
                case .permissions:
                    SetupPermissions()
                case .preferences:
                    AppPreferences()
                case .completion:
                    OnboardingFinished()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(.windowBackgroundColor))
            
            // Navigation buttons
            HStack {
                if onboardingManager.currentStep != .welcome {
                    Button("Back") {
                        withAnimation {
                            onboardingManager.retreatToPreviousStep()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if onboardingManager.currentStep == .completion {
                    Button("Get Started") {
                        onboardingManager.finishOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Continue") {
                        if onboardingManager.currentStep == .modelSelection {
                            Task {
                                await handleModelSelection()
                            }
                        } else {
                            withAnimation {
                                onboardingManager.advanceToNextStep()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    //.disabled(onboardingManager.currentStep == .modelSelection && onboardingManager.selectedCoreModel.isEmpty)
                }
            }
            .padding()
        }
        .frame(minWidth: 520, minHeight: 600)
    }
    
    private func handleModelSelection() async {
        let selectedModelName = onboardingManager.selectedCoreModel
        
        if let modelConfig = ModelConfiguration.getModelByName(selectedModelName) {
            print("Selected model: \(selectedModelName)")
            print("Model config: \(modelConfig)")
            
            // Store the selected model in AppSettings
            appSettings.currentModelName = selectedModelName
            
            // Add to installed models list if it's already downloaded
            // but don't download it now - this will happen when needed
            if appSettings.installedModels.contains(selectedModelName) {
                print("Model is already installed: \(selectedModelName)")
            } else {
                print("Model is not installed yet: \(selectedModelName)")
                // We'll download it later when actually needed
            }
            
            // Continue to the next step immediately
            await MainActor.run {
                onboardingManager.advanceToNextStep()
            }
        } else {
            print("Could not get model config for: \(selectedModelName)")
        }
    }
}

// MARK: - Preview Provider
struct Onboarding_Previews: PreviewProvider {
    static var previews: some View {
        Onboarding()
    }
} 