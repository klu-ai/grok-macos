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
/// Now includes logic for handling <think> ... </think> content and tool calls with collapsible sections.
struct MessageBubble: View {
    /// The message data to be displayed in the bubble.
    let message: Message
    
    /// Indicates if the message is currently being generated
    let isGenerating: Bool
    
    /// Tracks whether the reasoning content (if any) is collapsed.
    @State private var isReasoningCollapsed = true
    
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
        HStack(alignment: .top, spacing: 8) {
            // Avatar or icon
            if message.role == .assistant {
                Image(systemName: "brain")
                    .foregroundColor(.accentColor)
                    .font(.title2)
            } else {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
            
            // Message content
            VStack(alignment: .leading, spacing: 4) {
                // Message text
                MarkdownView(text: message.content)
                    .textSelection(.enabled)
                
                // Timestamp
                if let timestamp = message.timestamp {
                    Text(timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Copy button for assistant messages
            if message.role == .assistant {
                Button(action: copyMessage) {
                    Image(systemName: isPressed ? "checkmark" : "doc.on.doc")
                        .foregroundColor(isButtonHovered ? .accentColor : .secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isButtonHovered = hovering
                }
                .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 0) { pressing in
                    isPressed = pressing
                    if !pressing {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isPressed = false
                        }
                    }
                } perform: {}
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(message.role == .assistant ? Color(.windowBackgroundColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor).opacity(0.3), lineWidth: message.role == .assistant ? 1 : 0)
        )
    }
    
    private func copyMessage() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(message.content, forType: .string)
    }
}

/// A view for displaying tool call messages with expandable content
struct ToolCallMessageView: View {
    let message: Message
    let toolName: String
    let toolCallId: String?
    
    @State private var isExpanded = false
    
    init(message: Message, toolName: String, toolCallId: String? = nil) {
        self.message = message
        self.toolName = toolName
        self.toolCallId = toolCallId
    }
    
    var body: some View {
        // Wrap in an HStack with Spacers to match the assistant message width
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Tool call header
                HStack {
                    Image(systemName: "terminal.fill")
                        .foregroundColor(.secondary)
                    if case .toolResult = message.messageType {
                        Text("Tool result")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Tool: \(toolName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.windowBackgroundColor).opacity(0.3))
                .cornerRadius(8)
                .onTapGesture {
                    withAnimation { 
                        isExpanded.toggle() 
                    }
                }
                
                // Tool call content (expandable)
                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Result:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(message.content)
                            .font(.body)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.textBackgroundColor).opacity(0.2))
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(8)
            .background(Color(.windowBackgroundColor).opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1)
            )
            
            // Add spacer at the end to match assistant message layout
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16) // Match assistant message horizontal padding
    }
}