//  MessageBubble.swift
//  klu macos assistant
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
    
    /// Tracks which tool calls are expanded
    @State private var expandedToolCalls: [String: Bool] = [:]
    
    /// Environment object providing live LLM state (e.g. loading/generating).
    @EnvironmentObject var llm: RunLLM
    
    var body: some View {
        Group {
            switch message.messageType {
            case .text:
                standardMessageView
            case .toolCall(let name, let id):
                ToolCallMessageView(message: message, toolName: name, toolCallId: id)
            case .toolResult(let toolCallId):
                ToolCallMessageView(message: message, toolName: "Tool Result", toolCallId: toolCallId)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // Parsed content part for assistant messages
    struct ContentPart: Identifiable {
        let id = UUID()
        let text: String
        let toolCall: RunLLM.ToolCall?
    }
    
    // Parse content into text and tool call parts
    private func parseContent(_ content: String) -> [ContentPart] {
        let pattern = #"```json\n(.*?)\n```"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let matches = regex?.matches(in: content, range: NSRange(content.startIndex..., in: content)) ?? []
        
        var parts: [ContentPart] = []
        var lastIndex = content.startIndex
        
        for match in matches {
            let textRange = lastIndex..<content.index(content.startIndex, offsetBy: match.range.location)
            let textBefore = String(content[textRange])
            if !textBefore.isEmpty {
                parts.append(ContentPart(text: textBefore, toolCall: nil))
            }
            if let jsonRange = Range(match.range(at: 1), in: content) {
                let jsonString = String(content[jsonRange])
                if let jsonData = jsonString.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let id = jsonObject["id"] as? String,
                   let name = jsonObject["name"] as? String,
                   let parameters = jsonObject["parameters"] as? [String: Any] {
                    let toolCall = RunLLM.ToolCall(id: id, name: name, parameters: parameters)
                    parts.append(ContentPart(text: "", toolCall: toolCall))
                }
            }
            lastIndex = content.index(content.startIndex, offsetBy: match.range.upperBound)
        }
        
        if lastIndex < content.endIndex {
            let remainingText = String(content[lastIndex...])
            parts.append(ContentPart(text: remainingText, toolCall: nil))
        }
        
        return parts
    }
    
    // Standard message view for user/assistant messages
    private var standardMessageView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role.rawValue == "user" {
                Spacer(minLength: 60)
            }
            
            if message.role.rawValue == "user" {
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
                    if isGenerating {
                        if message.content.isEmpty {
                            HStack(alignment: .center, spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("generating...")
                                    .italic()
                                    .foregroundStyle(.secondary)
                            }
                        } else if message.content.contains("<think>") && !message.content.contains("</think>") {
                            HStack(alignment: .center, spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("thinking...")
                                    .italic()
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            let (reasoningContent, finalContent) = splitThinkTags(message.content)
                            if let reasoning = reasoningContent {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Button(action: { isReasoningCollapsed.toggle() }) {
                                            Image(systemName: isReasoningCollapsed ? "chevron.right" : "chevron.down")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        Text(isReasoningCollapsed ? "reasoning..." : "reasoning revealed")
                                            .italic()
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    if !isReasoningCollapsed {
                                        HStack(alignment: .top, spacing: 8) {
                                            Rectangle()
                                                .fill(.secondary)
                                                .frame(width: 2)
                                            MarkdownView(text: reasoning)
                                                .padding(.leading, 4)
                                        }
                                    }
                                }
                            }
                            let parts = parseContent(finalContent ?? message.content)
                            ForEach(parts) { part in
                                if let toolCall = part.toolCall {
                                    let isExpanded = expandedToolCalls[toolCall.id] ?? false
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Tool call header
                                        HStack {
                                            Image(systemName: "terminal.fill")
                                                .foregroundColor(.secondary)
                                            Text("Calling tool: \(toolCall.name)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
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
                                                expandedToolCalls[toolCall.id] = !isExpanded
                                            }
                                        }
                                        
                                        // Tool call parameters (expandable)
                                        if isExpanded {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Parameters:")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                Text("\(toolCall.parameters)")
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
                                } else {
                                    MarkdownView(text: part.text)
                                }
                            }
                        }
                    } else {
                        let (reasoningContent, finalContent) = splitThinkTags(message.content)
                        if let reasoning = reasoningContent {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Button(action: { isReasoningCollapsed.toggle() }) {
                                        Image(systemName: isReasoningCollapsed ? "chevron.right" : "chevron.down")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    Text(isReasoningCollapsed ? "reasoning..." : "reasoning revealed")
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                
                                if !isReasoningCollapsed {
                                    HStack(alignment: .top, spacing: 8) {
                                        Rectangle()
                                            .fill(.secondary)
                                            .frame(width: 2)
                                        MarkdownView(text: reasoning)
                                            .padding(.leading, 4)
                                    }
                                }
                            }
                        }
                        let parts = parseContent(finalContent ?? message.content)
                        ForEach(parts) { part in
                            if let toolCall = part.toolCall {
                                let isExpanded = expandedToolCalls[toolCall.id] ?? false
                                VStack(alignment: .leading, spacing: 8) {
                                    // Tool call header
                                    HStack {
                                        Image(systemName: "terminal.fill")
                                            .foregroundColor(.secondary)
                                        Text("Calling tool: \(toolCall.name)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
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
                                            expandedToolCalls[toolCall.id] = !isExpanded 
                                        }
                                    }
                                    
                                    // Tool call parameters (expandable)
                                    if isExpanded {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Parameters:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text("\(toolCall.parameters)")
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
                            } else {
                                MarkdownView(text: part.text)
                            }
                        }
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
            
            if message.role.rawValue != "user" {
                Spacer(minLength: 60)
            }
        }
    }
    
    /// Displays a loading indicator with a "thinking..." label.
    private func loadingView() -> some View {
        HStack(alignment: .center, spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("thinking...")
                .italic()
                .foregroundStyle(.secondary)
        }
    }
    
    /// Splits the content into (reasoning, final) by looking for <think> and </think>.
    private func splitThinkTags(_ content: String) -> (String?, String?) {
        let options: String.CompareOptions = [.caseInsensitive]
        guard let startRange = content.range(of: "<think>", options: options) else {
            // no <think> tag
            return (nil, content)
        }
        print("Debug: <think> tag detected in content: \(content)")
        guard let endRange = content.range(of: "</think>", options: options) else {
            // Found <think> but no closing tag
            let reasoning = String(content[startRange.upperBound...])
            return (reasoning, nil)
        }
        let reasoning = String(content[startRange.upperBound..<endRange.lowerBound])
        let final = content[..<startRange.lowerBound] + content[endRange.upperBound...]
        return (reasoning.trimmingCharacters(in: .whitespacesAndNewlines),
                final.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Copies the message content to the system clipboard
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