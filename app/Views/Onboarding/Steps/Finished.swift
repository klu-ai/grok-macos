//  OnboardingFinished.swift
//  klu macos assistant
//  Created by Stephen M. Walker II on 3/14/24.
//
//  Description:
//  This file defines the completion step of the onboarding process for the Klu macOS Assistant.
//  It provides users with a summary of what they can do with the app and offers suggestions
//  for initial tasks to try.
//
//  Core responsibilities:
//  - Displays a completion message and app icon
//  - Suggests initial tasks for users to try
//  - Ensures a smooth transition from onboarding to app usage
//
//  Usage:
//  - This view is presented as the final step in the onboarding process
//  - It uses SwiftUI for layout and design
//  - The SuggestionRow component is used to list and describe suggested actions
//
//  Dependencies:
//  - SwiftUI for UI components
//  - BounceEffectModifier for image animation

import SwiftUI

/// The completion step of the onboarding process.
struct OnboardingFinished: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)    
                //.modifier(BounceEffectModifier())
            
            Text("All set...")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Klu is now ready to assist you with your tasks.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Here are a few things you can try...")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                SuggestionRow(
                    icon: "calendar",
                    title: "Schedule a Meeting",
                    description: "Ask Klu to find a good time and create a calendar event"
                )
                
                SuggestionRow(
                    icon: "doc.text",
                    title: "Summarize Text",
                    description: "Copy some text and ask Klu to summarize it"
                )
                
                SuggestionRow(
                    icon: "magnifyingglass",
                    title: "Search Files",
                    description: "Ask Klu to find files on your Mac by content or name"
                )
                
                SuggestionRow(
                    icon: "keyboard",
                    title: "Use Shortcuts",
                    description: "Press ⌘ Space to quickly access Klu from anywhere"
                )
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
            }
            
            // Spacer()
            
            // Text("You can access these suggestions and more tips anytime from the Help menu.")
            //     .font(.caption)
            //     .foregroundColor(.secondary)
            //     .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Supporting Views

/// A row showing a suggested action
private struct SuggestionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
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

// MARK: - Helper Extensions
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview Provider
struct OnboardingFinished_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFinished()
            .frame(width: 600, height: 500)
    }
}

struct BounceEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.symbolEffect(.bounce)
        } else {
            content
        }
    }
} 