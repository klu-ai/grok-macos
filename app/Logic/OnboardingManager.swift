//
//  OnboardingManager.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages the onboarding state and flow for the application.
//  Coordinates the progression through onboarding steps and
//  maintains the completion status of various setup tasks.
//
//  Key features:
//  - State management
//  - Progress tracking
//  - Step coordination
//  - Persistence
//
//  Managed states:
//  - Onboarding completion
//  - Permission status
//  - Preferences setup
//  - UI tour progress (removed)
//  - Completion (with use cases shown)
//
//  Implementation notes:
//  - Uses AppStorage
//  - Observable object
//  - Thread-safe updates
//  - State validation
//
//  Usage:
//  - Track onboarding
//  - Manage progress
//  - Handle completion
//  - Reset if needed
//

import SwiftUI
import Combine

/// Manages the onboarding flow and progress tracking for the Klu assistant.
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    // MARK: - Published Properties
    
    /// The current step in the onboarding process
    @Published private(set) var currentStep: OnboardingStep = .welcome
    
    /// Whether onboarding has been completed
    @Published private(set) var isOnboardingComplete: Bool
    
    /// Progress through the onboarding steps (0.0 to 1.0)
    @Published private(set) var progress: Double = 0.0
    
    /// The selected core model name
    @Published var selectedCoreModel: String = ModelRegistry.shared.getDefaultModel(for: .core)
    
    // MARK: - Private Properties
    
    /// UserDefaults key for storing onboarding progress
    private let onboardingProgressKey = "onboardingProgress"
    private let onboardingCompleteKey = "onboardingComplete"
    
    // MARK: - Initialization
    
    private init() {
        // Load saved progress from UserDefaults
        let savedProgress = UserDefaults.standard.integer(forKey: onboardingProgressKey)
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: onboardingCompleteKey)
        
        // If onboarding is complete, set to completion step
        if isOnboardingComplete {
            self.currentStep = .completion
            self.progress = 1.0
        } else if let step = OnboardingStep(rawValue: savedProgress) {
            // Resume from last saved step
            self.currentStep = step
            self.progress = Double(savedProgress) / Double(OnboardingStep.totalSteps - 1)
        }
    }
    
    // MARK: - Public Methods
    
    /// Advances to the next onboarding step
    func advanceToNextStep() {
        guard !isOnboardingComplete else { return }
        
        let nextStepRawValue = min(currentStep.rawValue + 1, OnboardingStep.totalSteps - 1)
        if let nextStep = OnboardingStep(rawValue: nextStepRawValue) {
            currentStep = nextStep
            progress = Double(nextStepRawValue) / Double(OnboardingStep.totalSteps - 1)
            
            // Save progress
            UserDefaults.standard.set(nextStepRawValue, forKey: onboardingProgressKey)
            
            // Check if we've reached completion
            // if nextStep == .completion {
            //     completeOnboarding()
            // }
        }
    }

    func retreatToPreviousStep() {
        guard currentStep.rawValue > 0 else { return } 
        let previousStepRawValue = currentStep.rawValue - 1
        if let previousStep = OnboardingStep(rawValue: previousStepRawValue) {
            currentStep = previousStep
            progress = Double(previousStepRawValue) / Double(OnboardingStep.totalSteps - 1)
            
            // Save updated progress
            UserDefaults.standard.set(previousStepRawValue, forKey: onboardingProgressKey)
        }
    }

    func finishOnboarding() {
        // Only allow finishing if user is actually on the final step
        guard currentStep == .completion else { return }
        completeOnboarding()
    }
    
    /// Marks onboarding as complete
    func completeOnboarding() {
        currentStep = .completion
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: onboardingCompleteKey)
        progress = 1.0
    }
    
    /// Resets onboarding progress
    func resetOnboarding() {
        currentStep = .welcome
        isOnboardingComplete = false
        progress = 0.0
        UserDefaults.standard.set(0, forKey: onboardingProgressKey)
        UserDefaults.standard.set(false, forKey: onboardingCompleteKey)
    }
    
    /// Returns whether a specific step has been completed
    func isStepCompleted(_ step: OnboardingStep) -> Bool {
        return step.rawValue < currentStep.rawValue || isOnboardingComplete
    }
}

// MARK: - Onboarding Step Enum

/// Defines the steps in the onboarding process
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case modelSelection = 1
    case permissions = 2
    case preferences = 3
    //case uiTour
    case completion = 4
    
    static var totalSteps: Int { Self.allCases.count }
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Klu"
        case .modelSelection:
            return "Choose AI Model"
        case .permissions:
            return "Setup Permissions"
        case .preferences:
            return "Basic Preferences"
        //case .uiTour:
          //  return "Quick Tour"
        case .completion:
            return "All Set!"
        }
    }
    
    var systemImage: String {
        switch self {
        case .welcome:
            return "hand.wave.fill"
        case .modelSelection:
            return "cpu"
        case .permissions:
            return "lock.shield"
        case .preferences:
            return "gearshape.fill"
        //case .uiTour:
          //  return "rectangle.inset.filled.and.person.filled"
        case .completion:
            return "checkmark.circle.fill"
        }
    }
} 
