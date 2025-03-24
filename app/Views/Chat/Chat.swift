//
//  Chat.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Primary chat interface component that manages the display and interaction of chat messages.
//  This view handles message display, user input, and session management in a scrollable interface.
//
//  Key features:
//  - Scrollable message history
//  - Real-time message updates
//  - Session-based chat organization
//  - Efficient message rendering with LazyVStack
//  - Focus management for input field
//
//  Implementation notes:
//  - Uses SwiftUI for reactive UI updates
//  - Implements MVVM pattern with ChatViewModel
//  - Handles keyboard focus states
//  - Supports multiple chat sessions
//
//  Dependencies:
//  - ChatViewModel: Manages chat state and logic
//  - MessageBubble: Individual message display component
//  - Message: Data model for chat messages
//
//  Usage:
//  - Instantiate with a ChatViewModel
//  - Messages are displayed automatically
//  - Input field manages user interactions
//

import SwiftUI
import AVFoundation

struct BottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct ContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct ScrollViewSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

/// The main chat interface view component
struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @Binding var currentThread: Thread?
    @EnvironmentObject var runLLM: RunLLM
    @FocusState private var isFocused: Bool
    @State private var currentInput: String = ""
    @State private var showThinking: Bool = false
    @State private var isAtBottom: Bool = true
    @State private var window: NSWindow? // Capture window reference
    @State private var isMainWindowKey: Bool = false // Track key window status
    @State private var isRecordingFromChat: Bool = false
    @State private var chatAudioProcessor: AudioProcessor? = nil
    @State private var isLoadingWhisperModel: Bool = false
    
    var externalIsFocused: FocusState<Bool>.Binding
    
    // Improved scroll position tracking variables
    @State private var scrollViewHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    init(viewModel: ChatViewModel, currentThread: Binding<Thread?>, externalIsFocused: FocusState<Bool>.Binding) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._currentThread = currentThread
        self.externalIsFocused = externalIsFocused
    }
    
    var body: some View {
        VStack(spacing: 0) {
    // Toast-like UI for Whisper model download
    if WhisperTranscriptionManager.shared.isDownloadingModel {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor).opacity(0.9))
                .frame(width: 300, height: 40)
            Text(
                "Downloading model: \((WhisperTranscriptionManager.shared.modelDownloadProgress * 100).rounded())%"
            )
            .foregroundColor(.primary)
        }
        .padding(.bottom, 8)
        .transition(.opacity)
        .zIndex(99)
    }

            // Thinking indicator with download progress
            ZStack(alignment: .top) {
                if case .downloading(let modelName) = runLLM.loadState {
                    Text("Downloading \(modelName): \(Int(runLLM.progress * 100))%")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color(.windowBackgroundColor).opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 2)
                        .zIndex(1)
                } else if case .loading(let modelName) = runLLM.loadState {
                    Text("Loading \(modelName)")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color(.windowBackgroundColor).opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 2)
                        .zIndex(1)
                } else {
                    Text("Thinking...")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color(.windowBackgroundColor).opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 2)
                        .zIndex(1)
                        .opacity(showThinking ? 1 : 0)
                        .transition(.opacity)
                        .onChange(of: viewModel.isThinking) { oldValue, newValue in
                            if newValue {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showThinking = runLLM.output.isEmpty
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showThinking = false
                                }
                            }
                        }
                        .onChange(of: runLLM.output) { oldValue, newValue in
                            if viewModel.isThinking && !newValue.isEmpty && showThinking {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showThinking = false
                                }
                            }
                        }
                }
            }
            .frame(height: 0)
            .offset(y: 20)
            
            // Message list with improved scroll tracking
            ScrollViewReader { proxy in
                GeometryReader { scrollGeo in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            if let thread = currentThread {
                                ForEach(Array(thread.messages.enumerated()), id: \.element.id) { index, message in
                                    MessageBubble(message: message, isGenerating: false)
                                        .offset(y: index == 0 ? 30 : 0)
                                        .padding(.bottom, index == 0 ? 30 : 0)
                                }
                                if viewModel.isThinking {
                                    MessageBubble(message: Message(role: .assistant, content: runLLM.output + " ▋"), isGenerating: true)
                                        .id("generating")
                                }
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                                    .background(
                                        GeometryReader { innerGeo in
                                            Color.clear
                                                .preference(key: BottomPreferenceKey.self, value: innerGeo.frame(in: .global))
                                                .onAppear {
                                                    // Set initial state to "at bottom"
                                                    isAtBottom = true
                                                }
                                        }
                                    )
                            } else {
                                Text("No thread selected")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ContentSizePreferenceKey.self, value: geometry.size)
                            }
                        )
                    }
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: ScrollViewSizePreferenceKey.self, value: geometry.size)
                        }
                    )
                    .onPreferenceChange(BottomPreferenceKey.self) { bottomFrame in
                        let scrollViewFrame = scrollGeo.frame(in: .global)
                        
                        // Dynamic calculation of "at bottom" state with proportional threshold
                        let threshold = min(50, scrollViewHeight * 0.1) // 10% of view height or 50pt, whichever is smaller
                        isAtBottom = bottomFrame.maxY <= scrollViewFrame.maxY + threshold
                        
                        // Also check if user has manually scrolled to bottom
                        let scrolledToBottom = contentHeight - scrollOffset <= scrollViewHeight + threshold
                        if scrolledToBottom {
                            isAtBottom = true
                        }
                    }
                    .onPreferenceChange(ContentSizePreferenceKey.self) { size in
                        contentHeight = size.height
                    }
                    .onPreferenceChange(ScrollViewSizePreferenceKey.self) { size in
                        scrollViewHeight = size.height
                    }
                    .simultaneousGesture(
                        DragGesture().onChanged { value in
                            scrollOffset = value.translation.height
                        }
                    )
                    .onChange(of: runLLM.output) { oldValue, newValue in
                        if viewModel.isThinking && isAtBottom {
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: currentThread?.messages.count) { oldValue, newValue in
                        if let old = oldValue, let new = newValue, new > old && isAtBottom {
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    if !isAtBottom {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }) {
                                ZStack {
                                    Circle().fill(Color.black)
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12))
                                }
                                .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.borderless)
                            .padding()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            
            Divider()
            
            // Input area
            HStack(alignment: .bottom, spacing: 0) {
                TextField("Message assistant...", text: $currentInput)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .focused($isFocused)
                    .onSubmit { sendMessage() }
                    .submitLabel(.send)
                    .frame(minHeight: 32)
                    .accessibilityIdentifier("chatInputField")
                    .onChange(of: externalIsFocused.wrappedValue) { _, newValue in
                        if newValue {
                            isFocused = true
                        }
                    }
                    .background(
                        WindowAccessor(window: $window)
                            .onChange(of: window) { _, newWindow in
                                isMainWindowKey = newWindow?.isKeyWindow ?? false && newWindow?.title == "Klu Assistant"
                            }
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            
                                isFocused = true
                            
                        }
                    }

                HStack(spacing: 8) {
                    // Microphone button
                    Button(action: {
                        Task {
                            print("Microphone button pressed, isRecording: \(isRecordingFromChat)")
                            let manager = WhisperTranscriptionManager.shared
                            if !manager.isModelLoaded {
                                // Set the loading state before we start loading
                                isLoadingWhisperModel = true
                                await manager.loadWhisperModel()
                                // Reset loading state after model is loaded
                                isLoadingWhisperModel = false
                            }
                            
                            if isRecordingFromChat {
                                // We're currently recording, so stop
                                print("Stopping recording...")
                                chatAudioProcessor?.stopRecording()
                                
                                // Get the audio samples
                                guard let processor = chatAudioProcessor, !processor.audioSamples.isEmpty else {
                                    print("No audio processor or audio samples available")
                                    isRecordingFromChat = false
                                    return
                                }
                                
                                let samples = Array(processor.audioSamples)
                                print("Stopped recording with \(samples.count) samples")
                                // Debug audio samples
                                if !samples.isEmpty {
                                    let maxVal = samples.map { abs($0) }.max() ?? 0
                                    let minVal = samples.map { abs($0) }.min() ?? 0
                                    let avgVal = samples.map { abs($0) }.reduce(0, +) / Float(samples.count)
                                    print("Sample stats - Max: \(maxVal), Min: \(minVal), Avg: \(avgVal)")
                                }
                                
                                // Reset the local buffer
                                processor.purgeAudioSamples(keepingLast: 0)
                                
                                // Update state to indicate we're not recording
                                isRecordingFromChat = false
                    
                                // Transcribe - don't reset the processor until transcription is done
                                let recognized = await manager.transcribeAudioData(samples.map { Float($0) })
                                print("Transcription result: \(recognized)")
                                currentInput = recognized
                                
                                // Now it's safe to nil the processor
                                chatAudioProcessor = nil
                                isFocused = true
                            } else {
                                // Not recording, so start
                                print("Starting recording...")
                                let permission = await AudioProcessor.requestRecordPermission()
                                if !permission {
                                    print("Microphone permission denied")
                                    return
                                }
                                
                                // Create and retain a new audio processor
                                let processor = AudioProcessor()
                                do {
                                    // First set our state variable to retain the processor
                                    chatAudioProcessor = processor
                                    
                                    // Start recording
                                    try processor.startRecordingLive(inputDeviceID: nil) { chunk in
                                        // Optional: Process audio chunks if needed
                                        if chunk.count % 1000 == 0 {
                                            print("Recording in progress: \(chunk.count) samples so far")
                                        }
                                    }
                                    
                                    // Mark as recording (do this AFTER successful start)
                                    isRecordingFromChat = true
                                    print("Recording started successfully")
                                } catch {
                                    print("Error starting recording: \(error)")
                                    // Clean up on error
                                    chatAudioProcessor = nil
                                }
                            }
                        }
                    }) {
                        Image(systemName: getRecordingButtonIcon())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(isRecordingFromChat ? .red : .secondary)
                    }
                    
                    .padding(.bottom, 8)
                    .buttonStyle(.borderless)
                    .onHover { hovering in
                        if hovering || isRecordingFromChat {
                            // this is the wrong way to implement this and needs to be updated
                            //RoundedRectangle(cornerRadius: 6)
                                //.fill(isRecordingFromChat ? Color.red.opacity(0.1) : Color.secondary.opacity(0.05))
                        }
                    }
                
                    Button(action: {
                        if viewModel.isThinking {
                            // Stop generation
                            viewModel.stopGeneration()
                            isFocused = true
                        } else {
                            sendMessage()
                        }
                    }) {
                        Image(systemName: viewModel.isThinking ? "stop.circle.fill" : "arrow.up.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                            .foregroundColor(currentInput.isEmpty && !viewModel.isThinking ? .secondary : .primary)
                    }
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                    .buttonStyle(.borderless)
                    .disabled(!viewModel.isThinking && currentInput.isEmpty)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.textBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.windowBackgroundColor))
        } // Closing VStack
        .navigationTitle("Chat")
    }
    
    /// Determines the appropriate icon to display for the recording button based on current state
    private func getRecordingButtonIcon() -> String {
        // Show hourglass when model is downloading or we're in the loading state
        if (WhisperTranscriptionManager.shared.isDownloadingModel || isLoadingWhisperModel) && !isRecordingFromChat {
            return "hourglass.circle"
        } else if isRecordingFromChat {
            return "mic.circle.fill"
        } else {
            return "mic.fill"
        }
    }
    
    /// Handles sending a message from the input field.
    /// Validates that the input is not empty, sends the message, and clears the input field.
    private func sendMessage() {
        guard !currentInput.isEmpty, let thread = currentThread else { return }
        viewModel.sendMessage(currentInput, thread: thread)
        currentInput = ""
    }
}
