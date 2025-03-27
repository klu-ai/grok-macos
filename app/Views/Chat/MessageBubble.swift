//  MessageBubble.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  A reusable chat bubble component that renders individual messages in the chat interface.
//  Supports both user and assistant messages with different styling and layouts.
//  Includes markdown rendering capabilities for rich text display.
//
//  Key features:
//  - Distinct styling for user and assistant messages
//  - Markdown text rendering support
//  - Dynamic bubble sizing
//  - Timestamp display
//  - Adaptive layout and spacing
//  - Display a "thinking..." placeholder when the assistant is generating a response   <-- NEW CAPABILITY
//
//  Visual elements:
//  - Background color differentiation
//  - Message alignment (right for user, left for assistant)
//  - Padding and spacing consistency
//
//  Implementation notes:
//  - Uses SwiftUI for layout and styling
//  - Implements custom markdown parsing
//  - Handles message metadata display
//  - Supports dynamic content sizing
//
//  Usage:
//  - Instantiate with a Message model
//  - Automatically handles message type
//  - Renders markdown content appropriately
//

import SwiftUI
import AppKit // Added for NSPasteboard clipboard functionality

/// A SwiftUI view representing an individual message bubble in the chat interface.
struct MessageBubble: View {
    /// The message data to be displayed in the bubble.
    let message: Message
    
    /// Indicates if the message is currently being generated
    let isGenerating: Bool
    
    /// Tracks whether the mouse is hovering over the assistant message bubble.
    @State private var isHovering = false
    
    /// Tracks whether the mouse is hovering over the copy button itself.
    @State private var isButtonHovered = false
    
    /// Tracks whether the copy button is being pressed.
    @State private var isPressed = false
    
    /// Environment object providing live LLM state (e.g. loading/generating).
    @EnvironmentObject var llm: RunLLM
    
    var body: some View {
        Group {
            switch message.messageType {
            case .text:
                standardMessageView
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // Standard message view for user/assistant messages
    private var standardMessageView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            if message.role == .user {
                VStack(alignment: .trailing, spacing: 8) {
                    MarkdownView(text: message.content)
                    HStack {
                        // Copy button for user msg
                        ZStack {
                            Color.clear
                                .frame(width: 20, height: 20)
                            Button(action: copyMessage) {
                                Image(systemName: "square.on.square")
                                    .foregroundColor(isPressed ? .secondary : (isButtonHovered ? .primary : .secondary))
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .opacity(isHovering ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: isHovering)
                            .onHover { hovering in
                                isButtonHovered = hovering
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in isPressed = true }
                                    .onEnded { _ in isPressed = false }
                            )
                        }
                        Text(message.timestamp.formatted(.dateTime.hour().minute()))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.windowBackgroundColor).opacity(0.44))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onHover { hovering in
                    isHovering = hovering
                    if !hovering {
                        isButtonHovered = false
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // Assistant content
                    if isGenerating && message.content.isEmpty {
                        HStack(alignment: .center, spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("thinking...")
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        MarkdownView(text: message.content)
                    }
                    
                    // Timestamp and copy button
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.timestamp.formatted(.dateTime.hour().minute()))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        // Copy button with fixed frame
                        ZStack {
                            // Empty transparent view with fixed size to reserve space
                            Color.clear
                                .frame(width: 20, height: 20)
                            
                            // The actual button
                            Button(action: copyMessage) {
                                Image(systemName: "square.on.square")
                                    .foregroundColor(isPressed ? .secondary : (isButtonHovered ? .primary : .secondary))
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            // Only animate opacity, not position or size
                            .opacity(isHovering ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: isHovering)
                            // Add hover detection for the button
                            .onHover { hovering in
                                isButtonHovered = hovering
                            }
                            // Add press state detection
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in isPressed = true }
                                    .onEnded { _ in isPressed = false }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.windowBackgroundColor).opacity(0.0))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                // Use a simpler hover detection without nested animations
                .onHover { hovering in
                    // Don't animate the hover state itself to reduce flickering
                    isHovering = hovering
                    // If not hovering, ensure button hover state is also cleared
                    if !hovering {
                        isButtonHovered = false
                    }
                }
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func copyMessage() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(message.content, forType: .string)
    }
}