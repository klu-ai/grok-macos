//
//  BrowsingPreferences.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages browser integration and web browsing preferences for the application.
//  Provides a comprehensive interface for configuring browser behavior,
//  privacy settings, and data synchronization options.
//
//  Key features:
//  - Browser selection and integration
//  - Privacy controls
//  - Data management
//  - Search engine configuration
//  - Bookmark/history sync
//
//  Browser options:
//  - Multiple browser support:
//    * Safari
//    * Chrome
//    * Firefox
//    * Edge
//  - Search engine selection
//  - Tab behavior
//
//  Privacy settings:
//  - Private browsing mode
//  - Data clearing options
//  - History management
//  - Sync controls
//
//  Implementation notes:
//  - Uses AppStorage for preferences
//  - Implements browser detection
//  - Manages data synchronization
//  - Handles privacy features
//
//  Usage:
//  - Select default browser
//  - Configure privacy options
//  - Manage browsing data
//  - Set search preferences
//

import SwiftUI

/// View for managing browser-related preferences and settings.
struct BrowsingPreferences: View {
    // MARK: - State Properties
    @AppStorage("browserEnabled") private var browserEnabled = false
    @AppStorage("defaultBrowser") private var defaultBrowser = "Safari"
    @AppStorage("openLinksInNewTab") private var openLinksInNewTab = true
    @AppStorage("enablePrivateBrowsing") private var enablePrivateBrowsing = false
    @AppStorage("clearBrowsingDataOnQuit") private var clearBrowsingDataOnQuit = false
    @AppStorage("syncBookmarks") private var syncBookmarks = false
    @AppStorage("syncHistory") private var syncHistory = false
    @AppStorage("defaultSearchEngine") private var defaultSearchEngine = "Google"
    
    // Available browsers
    private let availableBrowsers = ["Safari", "Chrome", "Firefox", "Edge"]
    
    // Available search engines
    private let availableSearchEngines = ["Google", "DuckDuckGo", "Bing", "Ecosia"]
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Browser Integration", isOn: $browserEnabled)
            } footer: {
                Text("Enable Grok to use your browser for deep research")
            }
            
            if browserEnabled {
                Section("Browser Settings") {
                    VStack(alignment: .leading) {
                        Picker("Default Browser", selection: $defaultBrowser) {
                            ForEach(availableBrowsers, id: \.self) { browser in
                                Text(browser)
                                    .tag(browser)
                            }
                        }
                        Text("Select your default browser for opening links")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading) {
                        Picker("Default Search Engine", selection: $defaultSearchEngine) {
                            ForEach(availableSearchEngines, id: \.self) { engine in
                                Text(engine)
                                    .tag(engine)
                            }
                        }
                        Text("Select your preferred search engine for web searches")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading) {
                        Toggle("Open Links in New Tab", isOn: $openLinksInNewTab)
                        Text("Always open links in a new tab")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading) {
                        Toggle("Enable Private Browsing", isOn: $enablePrivateBrowsing)
                        Text("Use private browsing mode when opening links")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section("Data Sync") {
                    VStack(alignment: .leading) {
                        Toggle("Sync Bookmarks", isOn: $syncBookmarks)
                        Text("Sync browser bookmarks with Grok")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading) {
                        Toggle("Sync History", isOn: $syncHistory)
                        Text("Sync browsing history with Grok")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                        
                    VStack(alignment: .leading) {
                        Toggle("Clear Browsing Data on Quit", isOn: $clearBrowsingDataOnQuit)
                        Text("Automatically clear synced browsing data when quitting Grok")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section("Actions") {
                    Button("Sync Now") {
                        syncBrowserData()
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button("Clear Browser Cache") {
                        clearBrowserCache()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Private Methods
    private func syncBrowserData() {
        // Here you would implement the browser sync functionality
        // This is a placeholder for the actual implementation
    }
    
    private func clearBrowserCache() {
        // Here you would implement the browser cache clearing functionality
        // This is a placeholder for the actual implementation
    }
}

// MARK: - Preview Provider
struct BrowsingPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        BrowsingPreferences()
    }
}
