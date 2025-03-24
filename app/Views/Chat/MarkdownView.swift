//
//  MarkdownView.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/23/25.
//
//  Description:
//  This file defines a SwiftUI view for rendering markdown text into a formatted layout.
//  It supports parsing of markdown elements such as headers, code blocks, and lists,
//  and converts them into SwiftUI views for display within the chat interface.
//
//  Core responsibilities:
//  - Parses markdown text into identifiable elements
//  - Renders headers, code blocks, and lists with appropriate styling
//  - Supports inline markdown formatting such as bold text
//  - Handles streaming content with optimistic rendering of code blocks
//
//  Usage:
//  - Instantiate with a markdown string to render it as a SwiftUI view
//  - Supports dynamic content rendering based on markdown syntax
//
//  Dependencies:
//  - SwiftUI for building user interfaces
//

import SwiftUI

/// Represents a parsed markdown element with a unique identifier
struct MarkdownElement: Identifiable {
    let id = UUID()
    let view: AnyView
}

/// A view that renders markdown text into a formatted SwiftUI layout
struct MarkdownView: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    // Dynamic colors based on color scheme
    private var codeHeaderBackgroundColor: Color {
        colorScheme == .dark ? Color(.darkGray).opacity(0.3) : Color(.lightGray).opacity(0.2)
    }
    
    private var codeBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : Color.gray.opacity(0.1)
    }
    
    private var codeBorderColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2)
    }
    
    private var codeTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseMarkdownElements(text), id: \.id) { element in
                element.view
            }
        }
    }
    
    /// Parses markdown text into an array of MarkdownElements
    private func parseMarkdownElements(_ markdown: String) -> [MarkdownElement] {
        var result: [MarkdownElement] = []
        let lines = markdown.components(separatedBy: .newlines)
        var inCodeBlock = false
        var codeBlockContent = ""
        var codeLanguage = ""
        var codeBlockIndex = -1
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block - render enhanced code block
                    let codeView = createCodeBlockView(code: codeBlockContent, language: codeLanguage, isStreaming: false)
                    // Update the existing code block element instead of adding a new one
                    if codeBlockIndex >= 0 && codeBlockIndex < result.count {
                        result[codeBlockIndex] = MarkdownElement(view: AnyView(codeView))
                    } else {
                        result.append(MarkdownElement(view: AnyView(codeView)))
                    }
                    codeBlockContent = ""
                    codeLanguage = ""
                    inCodeBlock = false
                    codeBlockIndex = -1
                } else {
                    // Start of code block
                    inCodeBlock = true
                    // Extract language identifier if present
                    let remainingText = String(trimmedLine.dropFirst(3))
                    if !remainingText.isEmpty {
                        codeLanguage = remainingText
                    } else {
                        codeLanguage = "text"
                    }
                    
                    // Create a new code block with streaming state
                    let codeView = createCodeBlockView(code: "", language: codeLanguage, isStreaming: true)
                    result.append(MarkdownElement(view: AnyView(codeView)))
                    codeBlockIndex = result.count - 1
                }
                continue
            }
            
            if inCodeBlock {
                codeBlockContent.append(line + "\n")
                
                // Update the code block with current content
                let codeView = createCodeBlockView(code: codeBlockContent, language: codeLanguage, isStreaming: true)
                if codeBlockIndex >= 0 && codeBlockIndex < result.count {
                    result[codeBlockIndex] = MarkdownElement(view: AnyView(codeView))
                }
                
                // Check if this is the last line and the code block wasn't closed
                if index == lines.count - 1 {
                    // Keep the streaming state true for incomplete code blocks
                    continue
                }
                continue
            }
            
            if line.starts(with: "#") {
                let headerLevel = line.prefix { $0 == "#" }.count
                let headerText = line.dropFirst(headerLevel).trimmingCharacters(in: .whitespaces)
                let headerView: Text
                switch headerLevel {
                case 1:
                    headerView = Text(headerText).font(.largeTitle).bold()
                case 2:
                    headerView = Text(headerText).font(.title).bold()
                case 3:
                    headerView = Text(headerText).font(.title2).bold()
                default:
                    headerView = Text(headerText).font(.headline)
                }
                result.append(MarkdownElement(view: AnyView(headerView)))
                continue
            }
            
            if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                let itemContent = String(trimmedLine.dropFirst(2))
                let bullet = Text("• ").bold()
                let listItemText = parseInlineMarkdown(itemContent)
                let listItemView = HStack(alignment: .top, spacing: 4) {
                    bullet
                    listItemText
                }
                result.append(MarkdownElement(view: AnyView(listItemView)))
                continue
            }
            
            let textView = parseInlineMarkdown(line)
            result.append(MarkdownElement(view: AnyView(textView)))
        }
        
        return result
    }
    
    /// Creates an enhanced code block view with header and styling
    private func createCodeBlockView(code: String, language: String, isStreaming: Bool) -> some View {
        VStack(spacing: 0) {
            // Header bar with language and copy button
            HStack {
                Text(language)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.gray)
                    .padding(.leading, 12)
                
                Spacer()
                
                // Only show copy button if there's content to copy
                if !code.isEmpty {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(code, forType: .string)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                            Text("Copy")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 12)
                }
            }
            .padding(.vertical, 8)
            .background(codeHeaderBackgroundColor)
            
            // Code content (removed ScrollView to allow full height)
            VStack(alignment: .leading, spacing: 0) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(codeTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                
                // Add a blinking cursor indicator if code is still streaming
                if isStreaming {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(codeTextColor)
                            .frame(width: 2, height: 16)
                            .opacity(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : 0)
                            .animation(Animation.easeInOut(duration: 0.5).repeatForever(), value: Date().timeIntervalSince1970)
                    }
                    .padding(.leading, code.hasSuffix("\n") ? 0 : 4)
                }
            }
            .padding(12)
            .background(codeBackgroundColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(codeBorderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 2, x: 0, y: 1)
        .padding(.vertical, 8)
    }
    
    /// Parses inline markdown (e.g., bold text) into a Text view
    private func parseInlineMarkdown(_ text: String) -> Text {
        // First handle bold formatting with **
        let boldComponents = text.components(separatedBy: "**")
        var result = Text("")
        
        for (index, component) in boldComponents.enumerated() {
            if index % 2 == 0 {
                // For regular text or parts that might contain italics
                // Now handle italic formatting with single *
                let italicComponents = component.components(separatedBy: "*")
                var italicResult = Text("")
                
                for (iIndex, iComponent) in italicComponents.enumerated() {
                    if iIndex % 2 == 0 {
                        italicResult = italicResult + Text(iComponent)
                    } else {
                        italicResult = italicResult + Text(iComponent).italic()
                    }
                }
                
                result = result + italicResult
            } else {
                // For bold text
                result = result + Text(component).bold()
            }
        }
        
        return result
    }
}