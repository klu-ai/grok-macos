//
//  ThreadsSidebar.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  This file defines the ThreadsSidebar view, a SwiftUI component for displaying and managing chat threads
//  in the Klu macOS Assistant. It includes a searchable list of threads with support for renaming via
//  context menu, deletion with confirmation dialogs (via swipe, context menu, or Delete key), and
//  automatic selection of the next thread after deletion.
//
//  Core responsibilities:
//  - Displays a searchable list of chat threads with timestamps
//  - Allows renaming threads via context menu with in-place editing
//  - Manages thread deletion with confirmation via swipe, context menu, or Delete key
//  - Updates chat view to select the next thread after deletion
//  - Integrates with SwiftData for thread persistence
//  - Uses ThreadManager for thread management operations
//
//  Usage:
//  - Part of the main chat interface for thread navigation
//  - Supports renaming with a TextField triggered by context menu
//  - Confirms deletions with a native Alert dialog
//  - Responds to Delete key for selected threads
//  - Ensures chat continuity by selecting the next thread post-deletion
//
//  Dependencies:
//  - SwiftUI for reactive UI components
//  - SwiftData for thread and message persistence
//  - StoreKit for potential review requests
//  - AppManager for app-wide settings and state
//  - ThreadManager for thread management operations
//

import StoreKit
import SwiftData
import SwiftUI

struct ThreadsSidebar: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    @Binding var currentThread: Thread?
    @FocusState.Binding var isPromptFocused: Bool
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Thread.timestamp, order: .reverse) var threads: [Thread]
    @State var search = ""
    @State var selection: UUID?
    @Environment(\.requestReview) private var requestReview
    @AppStorage("newThreadOnLoad") private var newThreadOnLoad = true
    @EnvironmentObject var viewModel: ChatViewModel
    
    // Thread manager for thread operations
    private var threadManager: ThreadManager {
        ThreadManager(modelContext: modelContext)
    }

    // State for renaming and deletion confirmation
    @State private var editingThreadId: UUID?
    @State private var editingTitle: String = ""
    @State private var threadToDelete: Thread?
    @FocusState private var isEditing: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                threadList // Extracted List view
                if filteredThreads.isEmpty { // Simplified condition
                    ContentUnavailableView {
                        Label(threads.isEmpty ? "No threads yet" : "No results", systemImage: "message")
                            .font(.body)
                    }
                }
            }
            .searchable(text: $search, placement: .sidebar, prompt: "search")
        }
        .tint(appSettings.appTintColor.getColor())
        .environment(\.dynamicTypeSize, appSettings.appFontSize.getFontSize())
    }

    // MARK: - List View
    private var threadList: some View {
        List(selection: $selection) {
            Section {} // Adds space below the search bar
            ForEach(filteredThreads, id: \.id) { thread in
                ThreadRow(
                    thread: thread,
                    editingThreadId: $editingThreadId,
                    editingTitle: $editingTitle,
                    isEditing: _isEditing,
                    onTitleCommit: { newTitle in
                        threadManager.updateThreadTitle(thread, title: newTitle)
                    }
                )
                .swipeActions {
                    Button("Delete") {
                        threadToDelete = thread
                    }
                    .tint(.red)
                }
                .contextMenu {
                    Button {
                        editingThreadId = thread.id
                        editingTitle = thread.title ?? "Untitled"
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button {
                        threadToDelete = thread
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .tag(thread.id)
            }
            .onDelete(perform: deleteThreads)
        }
        .onChange(of: selection) {
            setCurrentThread(selection)
        }
        .onChange(of: currentThread) { selection = currentThread?.id }
        .listStyle(.sidebar)
        .onAppear {
            if currentThread == nil {
                if newThreadOnLoad {
                    let newThread = viewModel.createNewThread()
                    currentThread = newThread
                    selection = newThread.id
                    // Set focus to the prompt field when a new thread is created
                    DispatchQueue.main.async {
                        isPromptFocused = true
                    }
                } else if !threads.isEmpty {
                    selection = threads.first?.id
                }
            }
            // Only set isPromptFocused if currentThread is already set
            if currentThread != nil {
                isPromptFocused = true
            }
        }
        .onDeleteCommand {
            if let selectedId = selection, let thread = threads.first(where: { $0.id == selectedId }) {
                threadToDelete = thread
            }
        }
        .alert(item: $threadToDelete) { thread in
            Alert(
                title: Text("Delete Chat"),
                message: Text("This can't be undone. Are you sure?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteThread(thread)
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Thread Row Subview
    private struct ThreadRow: View {
        let thread: Thread
        @Binding var editingThreadId: UUID?
        @Binding var editingTitle: String
        @FocusState var isEditing: Bool
        let onTitleCommit: (String) -> Void

        var body: some View {
            if editingThreadId == thread.id {
                TextField("Thread Title", text: $editingTitle, onCommit: {
                    onTitleCommit(editingTitle)
                    editingThreadId = nil
                })
                .focused($isEditing)
                .onAppear {
                    isEditing = true
                }
                .font(.headline)
            } else {
                VStack(alignment: .leading) {
                    Text(thread.title ?? (thread.sortedMessages.first?.content ?? "untitled"))
                        .lineLimit(1)
                    Text("\(thread.timestamp.formatted())")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Helpers
    var filteredThreads: [Thread] {
        threads.filter { thread in
            search.isEmpty || thread.messages.contains { message in
                message.content.localizedCaseInsensitiveContains(search)
            }
        }
    }

    private func deleteThreads(at offsets: IndexSet) {
        let threadsToDelete = offsets.map { filteredThreads[$0] }
        for thread in threadsToDelete {
            threadManager.deleteThread(thread)
        }
        if let current = currentThread, threadsToDelete.contains(where: { $0.id == current.id }) {
            currentThread = filteredThreads.first
        }
    }

    private func deleteThread(_ thread: Thread) {
        threadManager.deleteThread(thread)
        if currentThread?.id == thread.id {
            currentThread = filteredThreads.first
        }
    }

    private func setCurrentThread(_ threadID: UUID?) {
        if let threadID = threadID {
            currentThread = threads.first { $0.id == threadID }
        } else {
            currentThread = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPromptFocused = true
        }
    }
}

#Preview {
    @FocusState var isPromptFocused: Bool
    ThreadsSidebar(
        currentThread: .constant(nil),
        isPromptFocused: $isPromptFocused
    )
}
