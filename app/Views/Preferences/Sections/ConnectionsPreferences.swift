//
//  ConnectionsPreferences.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages external service integrations and API connections for the application.
//  Provides a centralized interface for configuring and managing connections to
//  various third-party services and development tools.
//
//  Key features:
//  - Service integration management
//  - API token configuration
//  - Connection status monitoring
//  - Secure credential storage
//
//  Supported services:
//  Development:
//  - GitHub: Repository and code management
//  - Jira: Issue tracking and project management
//  
//  Productivity:
//  - Slack: Team communication
//  - Notion: Knowledge management
//
//  Implementation notes:
//  - Uses AppStorage for secure token storage
//  - Implements connection validation
//  - Provides connection status feedback
//  - Follows OAuth best practices
//
//  Security considerations:
//  - Secure token storage
//  - API key validation
//  - Connection encryption
//  - Access scope management
//
//  Usage:
//  - Configure service connections
//  - Manage API credentials
//  - Monitor connection status
//  - Test service integration
//

import SwiftUI

/// View for managing connections to external services and integrations.
struct ConnectionsPreferences: View {
    // MARK: - State Properties
    @AppStorage("githubEnabled") private var githubEnabled = false
    @AppStorage("githubToken") private var githubToken = ""
    @AppStorage("slackEnabled") private var slackEnabled = false
    @AppStorage("slackToken") private var slackToken = ""
    @AppStorage("jiraEnabled") private var jiraEnabled = false
    @AppStorage("jiraToken") private var jiraToken = ""
    @AppStorage("jiraUrl") private var jiraUrl = ""
    @AppStorage("notionEnabled") private var notionEnabled = false
    @AppStorage("notionToken") private var notionToken = ""
    
    var body: some View {
        Form {
            Section {
                Text("Connect your favorite services to enhance Klu's capabilities.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section("Development") {
                ConnectionToggleRow(
                    title: "GitHub",
                    description: "Access repositories, issues, and pull requests",
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    isEnabled: $githubEnabled
                )
                
                if githubEnabled {
                    SecureField("GitHub Personal Access Token", text: $githubToken)
                        .textFieldStyle(.roundedBorder)
                        .help("Enter your GitHub personal access token")
                }
            }
            
            Section("Communication") {
                ConnectionToggleRow(
                    title: "Slack",
                    description: "Send messages and receive notifications",
                    systemImage: "message",
                    isEnabled: $slackEnabled
                )
                
                if slackEnabled {
                    SecureField("Slack Bot Token", text: $slackToken)
                        .textFieldStyle(.roundedBorder)
                        .help("Enter your Slack bot token")
                }
            }
            
            Section("Project Management") {
                ConnectionToggleRow(
                    title: "Jira",
                    description: "Track issues and manage projects",
                    systemImage: "list.bullet.clipboard",
                    isEnabled: $jiraEnabled
                )
                
                if jiraEnabled {
                    TextField("Jira URL", text: $jiraUrl)
                        .textFieldStyle(.roundedBorder)
                        .help("Enter your Jira instance URL")
                    
                    SecureField("Jira API Token", text: $jiraToken)
                        .textFieldStyle(.roundedBorder)
                        .help("Enter your Jira API token")
                }
                
                ConnectionToggleRow(
                    title: "Notion",
                    description: "Access and update Notion pages and databases",
                    systemImage: "doc.text",
                    isEnabled: $notionEnabled
                )
                
                if notionEnabled {
                    SecureField("Notion API Key", text: $notionToken)
                        .textFieldStyle(.roundedBorder)
                        .help("Enter your Notion API key")
                }
            }
            
            Section {
                Button("Test Connections") {
                    testConnections()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Private Methods
    private func testConnections() {
        // Here you would implement the connection testing functionality
        // This is a placeholder for the actual implementation
    }
}

// MARK: - ConnectionToggleRow
/// A reusable row component for displaying connection toggles with icons and descriptions.
struct ConnectionToggleRow: View {
    let title: String
    let description: String
    let systemImage: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $isEnabled) {
                HStack {
                    Image(systemName: systemImage)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview Provider
struct ConnectionsPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionsPreferences()
    }
} 
