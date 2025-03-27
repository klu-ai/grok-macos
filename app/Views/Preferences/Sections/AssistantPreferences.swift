//
//  AssistantPreferences.swift
//  Grok macOS assistant
//
//  Created by Claude AI on 3/11/2024.
//
//  Description:
//  This file defines the AssistantPreferences view for the Grok macOS assistant.
//  It provides an interface for users to customize the system prompt used by the AI assistant.
//

import SwiftUI

/// AssistantPreferences provides a UI for editing the system prompt.
struct AssistantPreferences: View {
    @AppStorage("systemPrompt") private var systemPrompt: String = AppSettings.defaultSystemPrompt
    
    var body: some View {
        Form {
            Section(header: Text("System Prompt")) {
                TextEditor(text: $systemPrompt)
                    .font(.body)
                    .frame(minHeight: 200)
                    .lineSpacing(10.0)
                    .padding(16)
                    .cornerRadius(16)
                    .colorMultiply(.gray)
                    .scrollContentBackground(.hidden)
                
                Text("Use the following placeholders for dynamic values:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("Customize system prompt for Grok's personality").font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Reset to Default") {
                        systemPrompt = AppSettings.defaultSystemPrompt
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 2)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AssistantPreferences()
} 