//
//  FloatingChat.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 3/06/25.
//
//  Description:
//  Implements a floating chat window that provides a minimalist interface for interacting
//  with the AI assistant. The window stays on top of other windows and can be toggled
//  with a keyboard shortcut.
//
//  Key features:
//  - Floating window with customizable size and position
//  - Message history with auto-scrolling and scroll position tracking
//  - Input bar with action buttons for attachments, web search, model selection, and voice input
//  - Creates and manages a dedicated chat thread
//  - Keyboard shortcut support for visibility toggling
//  - Dark/light mode compatible UI
//
//  Core components:
//  - FloatingChatWindow: Main view managing the chat interface and window behavior
//  - ChatViewModel: Handles message sending and thread management
//  - WindowAccessor: Configures NSWindow properties for floating behavior
//  - ViewOffsetKey: Tracks scroll position for auto-scrolling
//
//  Dependencies:
//  - SwiftUI for UI components
//  - AppKit for window management
//  - KeyboardShortcuts for hotkey support
//

import SwiftData
import SwiftUI
import AppKit
import KeyboardShortcuts

extension NSWindow {
    func toggleVisibility() {
        if isVisible {
            orderOut(nil)
        } else {
            makeKeyAndOrderFront(nil)
        }
    }
}

struct FloatingChatWindow: View {
    let modelContext: ModelContext
    @StateObject private var viewModel: ChatViewModel
    @State private var currentThread: Thread? = nil
    @FocusState private var isInputFocused: Bool
    @State private var window: NSWindow?
    @State private var inputText: String = ""
    @State private var isAtBottom: Bool = true
    @EnvironmentObject var appSettings: AppSettings

    private let windowWidth: CGFloat = 400
    private let windowHeight: CGFloat = 500

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self._viewModel = StateObject(wrappedValue: ChatViewModel(runLLM: RunLLM(), modelContext: modelContext, appSettings: AppSettings()))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 8) {
                Button(action: {
                    window?.close()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(currentThread?.messages.isEmpty ?? true ? 0 : 1)
                
                Spacer()
                
                Button(action: {
                    // Open in main window
                    if let mainWindow = NSApp.windows.first(where: { $0.title == "Klu Assistant" }) {
                        WindowManager.shared.updateMainWindow(mainWindow)
                    }
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    currentThread = viewModel.createNewThread()
                }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // Messages 
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        if let thread = currentThread {
                            ForEach(thread.sortedMessages, id: \.id) { message in
                                MessageBubble(message: message, isGenerating: false)
                            }
                            if viewModel.isThinking {
                                MessageBubble(message: Message(role: .assistant, content: viewModel.runLLM.output + " ▋"), isGenerating: true)
                                    .id("generating")
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        } else {
                            Text("No thread selected")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: viewModel.runLLM.output) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: currentThread?.messages.count) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: ViewOffsetKey.self, value: geo.frame(in: .global).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) { offset in
                        isAtBottom = offset >= (window?.contentView?.frame.height ?? 0) - 50
                    }
                }
            }

            // Input Bar
            VStack(spacing: 0) {
                TextField("Message assistant...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }
                    .submitLabel(.send)
                HStack(spacing: 12) {
                    Button(action: { /* Add attachment */ }) {
                        Image(systemName: "paperclip")
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { /* Search web */ }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { /* Switch model */ }) {
                        Text("4.5")
                            .foregroundColor(.secondary.opacity(0.8))
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { /* Voice-to-text */ }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(inputText.isEmpty ? .secondary.opacity(0.8) : .primary)
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .padding(.vertical, 8)
            .background(.background.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: windowWidth, height: windowHeight)
        .background(Color(.windowBackgroundColor).opacity(0.4))
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.7)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
        .draggable(window: window)
        .background(WindowAccessor(window: $window).onChange(of: window) { _, newWindow in
            if let window = newWindow {
                window.level = .floating
                window.isOpaque = false
                window.backgroundColor = .clear
                window.styleMask = [.borderless]
                window.isMovable = true
                window.isReleasedWhenClosed = false
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                
                // Set window to have rounded corners
                window.hasShadow = false // Disable default window shadow since we're using SwiftUI shadow
                if let contentView = window.contentView {
                    contentView.wantsLayer = true
                    contentView.layer?.cornerRadius = 12
                    contentView.layer?.masksToBounds = true
                }
            }
        })
        .onChange(of: currentThread?.messages.count) { _, count in
            if let window = window {
                // Check if there's a response from assistant
                if let thread = currentThread, 
                   thread.messages.contains(where: { $0.role == .assistant }) {
                    window.styleMask.insert(.resizable)
                    window.setContentSize(NSSize(width: windowWidth, height: windowHeight))
                } else {
                    window.styleMask.remove(.resizable)
                    window.setContentSize(NSSize(width: windowWidth, height: windowHeight))
                }
            }
        }
        .onAppear {
            currentThread = viewModel.createNewThread()
            isInputFocused = true
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty, let thread = currentThread else { return }
        viewModel.sendMessage(inputText, thread: thread)
        inputText = ""
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if (viewModel.isThinking || currentThread?.messages.count ?? 0 > 0) && isAtBottom {
            withAnimation {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
}

struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

extension KeyboardShortcuts.Name {
    static let toggleFloatingChat = Self("toggleFloatingChat")
}

// Add DraggableModifier for window dragging
struct DraggableModifier: ViewModifier {
    @State private var isDragging: Bool = false
    let window: NSWindow?
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard let window = window else { return }
                        let currentPosition = window.frame.origin
                        let newPosition = CGPoint(
                            x: currentPosition.x + value.location.x - value.startLocation.x,
                            y: currentPosition.y - (value.location.y - value.startLocation.y)
                        )
                        window.setFrameOrigin(newPosition)
                    }
            )
    }
}

extension View {
    func draggable(window: NSWindow?) -> some View {
        modifier(DraggableModifier(window: window))
    }
}
