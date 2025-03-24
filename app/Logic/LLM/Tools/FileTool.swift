//
//  FileTool.swift
//  klu
//
//  Created by Stephen M. Walker II on 3/13/25.
//
//  Description:
//  This file provides file system operations functionality as a tool for the RunLLM class.
//  It handles listing files in a specified directory with detailed attributes.
//
//  Usage:
//  - Used by the FunctionCalls.swift for the list_files tool.
//  - Lists files and directories with metadata.
//
//  Dependencies:
//  - Foundation: Provides core functionality.

import Foundation
import CoreGraphics

/// Extension to RunLLM class providing file system operations
extension RunLLM {
    /// Lists files in a specified directory
    func listFiles(directory: String) throws -> String {
        print("🔍 DEBUG: listFiles called for directory: \(directory)")
        let directoryURL = URL(fileURLWithPath: directory)
        
        // Log sandbox status
        #if DEBUG
        // Using process info environment to check sandbox status instead of deprecated appStoreReceiptURL
        let processInfo = ProcessInfo.processInfo
        let isSandboxed = processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
        print("🔒 DEBUG: App sandbox status: \(isSandboxed ? "Sandboxed" : "Not sandboxed")")
        #endif
        
        // Perform a preliminary check to understand directory access permissions
        let permissionsCheck = checkDirectoryPermissions(directory)
        print("🔒 DEBUG: Directory permissions check: \(permissionsCheck)")
        
        // Ensure the directory exists
        guard FileManager.default.fileExists(atPath: directoryURL.path) else {
            print("❌ DEBUG: Directory does not exist: \(directory)")
            throw RunLLMError.invalidParameters("Directory does not exist at path: \(directory)")
        }
        
        // Check if appSettings is nil and initialize if needed
        if self.appSettings == nil {
            print("⚠️ DEBUG: AppSettings is nil, initializing new instance")
            self.appSettings = AppSettings()
        }
        
        // Check if list_files tool is enabled
        if let settings = self.appSettings {
            let isEnabled = settings.isToolEnabled("list_files")
            print("🔧 DEBUG: list_files tool enabled: \(isEnabled)")
            
            guard isEnabled else {
                print("❌ DEBUG: File listing is disabled in app settings")
                throw RunLLMError.invalidParameters("File listing is disabled in app settings")
            }
        }
        
        // Check full disk access status if trying to access a potentially protected directory
        let potentiallyProtectedDirectories = [
            "/Library", 
            "/System", 
            "/Users", 
            "/Applications", 
            "/private", 
            "/var",
            "/etc"
        ]
        
        let needsFullDiskAccess = potentiallyProtectedDirectories.contains { directory.hasPrefix($0) }
        if needsFullDiskAccess {
            print("⚠️ DEBUG: Directory \(directory) may require full disk access")
            // Check permission state
            let permissionManager = PermissionManager()
            print("⚠️ DEBUG: Current full disk access status: \(permissionManager.fullDiskAccessStatus.rawValue)")
        }
        
        do {
            print("🔍 DEBUG: Attempting to read directory contents at: \(directoryURL.path)")
            
            // Measure timing for directory access
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directoryURL, 
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .creationDateKey], 
                options: [.skipsHiddenFiles]
            )
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("✅ DEBUG: Directory read completed in \(String(format: "%.3f", timeElapsed))s")
            
            var result = "Contents of \(directory):\n"
            print("📂 DEBUG: Found \(fileURLs.count) files in directory")
            
            // Check if we found any files at all
            if fileURLs.isEmpty {
                print("⚠️ DEBUG: Directory is empty or access is restricted")
                result += "No files found (directory may be empty or access restricted)\n"
            }
            
            // Count of successfully processed files
            var processedCount = 0
            
            for fileURL in fileURLs.prefix(100) { // Limit to first 100 for safety
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .creationDateKey])
                    let isDirectory = resourceValues.isDirectory ?? false
                    let fileSize = resourceValues.fileSize ?? 0
                    let creationDate = resourceValues.creationDate ?? Date()
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    dateFormatter.timeStyle = .short
                    let dateString = dateFormatter.string(from: creationDate)
                    
                    let fileSizeString = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
                    let fileName = fileURL.lastPathComponent
                    let fileType = isDirectory ? "Directory" : "File"
                    
                    result += "\(fileName) (\(fileType), \(fileSizeString), \(dateString))\n"
                    processedCount += 1
                } catch {
                    print("⚠️ DEBUG: Error accessing attributes for file \(fileURL.path): \(error.localizedDescription)")
                    result += "\(fileURL.lastPathComponent) (Error: Unable to access file attributes)\n"
                }
            }
            
            if fileURLs.count > 100 {
                print("⚠️ DEBUG: Truncated listing to first 100 files (total: \(fileURLs.count))")
                result += "... and \(fileURLs.count - 100) more files (listing truncated)\n"
            }
            
            print("✅ DEBUG: Successfully processed \(processedCount) of \(min(fileURLs.count, 100)) files in \(directory)")
            return result
        } catch {
            print("❌ DEBUG: Error listing directory contents: \(error.localizedDescription)")
            
            // Additional error context
            if let nsError = error as NSError? {
                print("❌ DEBUG: Error domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ DEBUG: Error details: \(nsError.userInfo)")
                
                // Common error codes
                if nsError.domain == NSCocoaErrorDomain {
                    switch nsError.code {
                    case NSFileReadNoSuchFileError:
                        print("❌ DEBUG: File not found error (this shouldn't happen since we checked existence)")
                    case NSFileReadNoPermissionError:
                        print("❌ DEBUG: Permission denied - likely missing full disk access")
                    case NSFileReadInvalidFileNameError:
                        print("❌ DEBUG: Invalid file name")
                    default:
                        print("❌ DEBUG: Other Cocoa file system error")
                    }
                }
            }
            
            throw RunLLMError.invalidParameters("Failed to list files: \(error.localizedDescription)")
        }
    }
    
    /// Helper method to check directory permissions
    private func checkDirectoryPermissions(_ directory: String) -> String {
        let fileManager = FileManager.default
        var result = ""
        
        // Check if directory exists
        if !fileManager.fileExists(atPath: directory) {
            return "Directory doesn't exist"
        }
        
        // Check if directory is readable
        if fileManager.isReadableFile(atPath: directory) {
            result += "Readable: Yes. "
        } else {
            result += "Readable: No. "
        }
        
        // Check if directory is writable
        if fileManager.isWritableFile(atPath: directory) {
            result += "Writable: Yes. "
        } else {
            result += "Writable: No. "
        }
        
        // Attempt to get directory attributes
        do {
            let attributes = try fileManager.attributesOfItem(atPath: directory)
            
            // Get owner and group
            if let owner = attributes[FileAttributeKey(rawValue: "NSFileOwnerAccountName")] as? String {
                result += "Owner: \(owner). "
            }
            
            if let group = attributes[FileAttributeKey(rawValue: "NSFileGroupOwnerAccountName")] as? String {
                result += "Group: \(group). "
            }
            
            // Get permissions
            if let permissions = attributes[FileAttributeKey.posixPermissions] as? NSNumber {
                result += "Permissions: \(permissions). "
            }
        } catch {
            result += "Cannot read attributes: \(error.localizedDescription)"
        }
        
        return result
    }
} 