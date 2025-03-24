// Welcome.swift
//  klu macos assistant
//  Created by Stephen M. Walker II on 3/14/24.
//
//  Description:
//  This file defines the welcome step of the onboarding process for the Grok macOS Assistant.
//  It introduces users to the app's key features and provides a native macOS experience.
//
//  Core responsibilities:
//  - Displays a welcome message and app icon
//  - Highlights key features of the Grok assistant
//  - Ensures a consistent and engaging onboarding experience
//
//  Usage:
//  - This view is presented as the first step in the onboarding process
//  - It uses SwiftUI for layout and design
//  - The FeatureRow component is used to list and describe app features
//
//  Dependencies:
//  - SwiftUI for UI components
//  - BounceEffectModifier for image animation

import SwiftUI

/// The welcome step of the onboarding process.
struct Welcome: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("MenuBarIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 60)
                .onTapGesture {
                    // Skip directly to completion by calling completeOnboarding
                    OnboardingManager.shared.completeOnboarding()
                }
            //    .modifier(BounceEffectModifier())
            
            Text("Welcome to Grok")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your macOS AI assistant, built natively for macOS 15.0+")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(icon: "apple.logo", title: "Native Experience", description: "Built specifically for macOS with native UI and interactions")
                FeatureRow(icon: "apple.intelligence", title: "Multi Model AI", description: "Advanced AI models for intelligence, reasoning, and more")
                FeatureRow(icon: "lock.shield", title: "Privacy First", description: "Your data stays on your device with local processing")
                FeatureRow(icon: "rectangle.connected.to.line.below", title: "System Integration", description: "Seamlessly works with your calendar, files, and more")
            }
            .padding(.vertical)
        }
        .padding()
    }
}

/// A reusable row component for displaying features
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview Provider
struct Welcome_Previews: PreviewProvider {
    static var previews: some View {
        Welcome()
            .frame(width: 600, height: 400)
    }
} 