//
//  HardwarePreferences.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Comprehensive hardware monitoring and configuration interface that provides
//  real-time system resource information and hardware-specific settings.
//  Integrates with IOKit and Metal for detailed hardware insights.
//
//  Key features:
//  - Real-time CPU usage monitoring
//  - RAM and VRAM capacity tracking
//  - GPU information display
//  - Resource guardrails configuration
//  - System architecture details
//
//  Hardware monitoring:
//  - CPU: Architecture, instruction set, usage
//  - Memory: RAM capacity and usage
//  - GPU: Type, VRAM capacity, utilization
//  - System: Power management, thermal state
//
//  Implementation notes:
//  - Uses IOKit for hardware access
//  - Implements Metal for GPU information
//  - Timer-based resource monitoring
//  - Persistent settings via AppStorage
//
//  Performance considerations:
//  - Efficient polling intervals
//  - Resource-aware monitoring
//  - Automatic cleanup on view dismissal
//  - Optimized data updates
//

import SwiftUI
import Foundation
import IOKit
import IOKit.pwr_mgt
import Metal
import MLXLMCommon
import Darwin

/// View for managing hardware-related preferences and monitoring system resources.
struct HardwarePreferences: View {
    // MARK: - State Properties
    @AppStorage("guardrailsLevel") private var guardrailsLevel = "Balanced"
    @AppStorage("customMemoryUtilization") private var customMemoryUtilization: Double = 50.0 // Default to 50%
    @AppStorage("selectedCoreModel") private var selectedCoreModel = CoreModels.defaultModel
    @AppStorage("selectedReasoningModel") private var selectedReasoningModel = ReasoningModels.defaultModel
    @AppStorage("selectedVisionModel") private var selectedVisionModel = VisionModels.defaultModel
    @AppStorage("selectedAudioModel") private var selectedAudioModel = AudioModels.defaultModel
    @AppStorage("selectedEmbeddingModel") private var selectedEmbeddingModel = EmbeddingModels.defaultModel
    
    @State private var cpuArchitecture = "ARM64"
    @State private var instructionSet = "AdvSIMD"
    @State private var totalMemory: UInt64 = 0
    @State private var usedMemory: UInt64 = 0
    @State private var memoryUsage: Double = 0
    @State private var pageSize: UInt64 = 0
    @State private var cpuUsage: Double = 0
    @State private var gpuInfo: [(type: String, vram: UInt64)] = []
    @State private var timer: Timer?
    @State private var previousCPULoad: host_cpu_load_info?
    
    private let guardrailsLevels = ["Off", "Relaxed", "Balanced", "Strict", "Custom"]
    
    // Memory utilization percentages for each preset level
    private var guardrailPercentage: Int {
        switch guardrailsLevel {
        case "Off": return 100
        case "Relaxed": return 80
        case "Balanced": return 60
        case "Strict": return 40
        case "Custom": return Int(customMemoryUtilization)
        default: return 60 // Default to Balanced
        }
    }
    
    var estimatedModelMemory: UInt64 {
        let selectedModels = [
            CoreModels.available.first(where: { $0.name == selectedCoreModel }),
            ReasoningModels.available.first(where: { $0.name == selectedReasoningModel }),
            VisionModels.available.first(where: { $0.name == selectedVisionModel }),
            AudioModels.available.first(where: { $0.name == selectedAudioModel }),
            EmbeddingModels.available.first(where: { $0.name == selectedEmbeddingModel })
        ].compactMap { $0 }
        return selectedModels.map { $0.size }.reduce(0, +)
    }
    
    var memoryUsageColor: Color {
        switch memoryUsage {
        case ..<50: return .green
        case ..<75: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        Form {
            
            Section("GPUs") {
                ForEach(gpuInfo, id: \.type) { gpu in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(gpu.type)
                            Spacer()
                            Text("Metal")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        HStack {
                            Text("VRAM")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatBytes(gpu.vram))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        
                        if let device = MTLCreateSystemDefaultDevice() {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Features")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    if device.supportsFamily(.apple3) {
                                        Text("Apple 3")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    
                                    if device.supportsRaytracing {
                                        Text("Ray Tracing")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    
                                    Text("Unified Memory")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // DONT THINK THESE ARE NEEDED

            // Section("CPU") {
            //     HStack {
            //         Text("Architecture")
            //         Spacer()
            //         Text(cpuArchitecture)
            //             .foregroundStyle(.secondary)
            //     }
                
            //     HStack {
            //         Text("Instruction Set")
            //         Spacer()
            //         Text(instructionSet)
            //             .foregroundStyle(.secondary)
            //     }
            // }
            
            // Section("Memory Capacity") {
            //     HStack {
            //         Text("RAM")
            //         Spacer()
            //         Text(formatBytes(ramCapacity))
            //             .foregroundStyle(.secondary)
            //     }
                
            //     HStack {
            //         Text("VRAM")
            //         Spacer()
            //         Text(formatBytes(vramCapacity))
            //             .foregroundStyle(.secondary)
            //     }
            // }
            
            Section("Resource Monitor") {
                VStack(alignment: .leading, spacing: 12) {
                    // CPU Usage
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("CPU")
                            .font(.headline)
                            Spacer()
                            Text("\(String(format: "%.1f", cpuUsage))%")
                        }
                        ProgressView(value: cpuUsage, total: 100)
                            .tint(resourceUsageColor(cpuUsage))
                    }
                    
                    Divider()
                    
                    // Memory Usage
                    VStack(alignment: .leading, spacing: 8) {
                        
                        // Used Memory
                        HStack {
                            Text("Memory")
                            .font(.headline)
                            Spacer()
                            Text("\(formatBytes(usedMemory)) (\(String(format: "%.1f", memoryUsage))%)")
                                .foregroundStyle(.secondary)
                        }
                        
                        // Memory Usage Bar
                        ProgressView(value: memoryUsage, total: 100)
                            .tint(memoryUsageColor)

                        Divider()

                        // Total Memory
                        HStack {
                            Text("Available Memory (RAM / VRAM)")
                            Spacer()
                            Text("\(formatBytes(totalMemory)) (\(gpuInfo.first?.vram != nil ? formatBytes(gpuInfo.first!.vram) : "Unknown"))")
                                .foregroundStyle(.secondary)
                        }

                        // Model Memory
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Maximum Model Usage")
                                Text("Estimate based on all models loaded simultaneously")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(formatBytes(estimatedModelMemory))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Guardrails") {
                Picker("Memory Limit", selection: $guardrailsLevel) {
                    ForEach(guardrailsLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                
                if guardrailsLevel != "Off" {
                    HStack {
                        Text("Memory Utilization Limit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(guardrailPercentage)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                if guardrailsLevel == "Custom" {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Set Custom Utilization Limit \(Int(customMemoryUtilization))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Slider(value: $customMemoryUtilization, in: 0...100, step: 10)
                                .frame(minWidth: 300)
                                
                        }
                        
                        
                    }
                    .padding(.vertical, 4)
                    
                   
                }
                
                Text("Guardrails help prevent system overload by managing overall memory usage.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            updateSystemInfo()
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            updateResourceUsage()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateSystemInfo() {
        // Get total physical memory using sysctl
        var size = MemoryLayout<UInt64>.size
        var memSize: UInt64 = 0
        sysctlbyname("hw.memsize", &memSize, &size, nil, 0)
        totalMemory = memSize
        
        // Get page size
        var pageSize64: UInt64 = 0
        sysctlbyname("hw.pagesize", &pageSize64, &size, nil, 0)
        pageSize = pageSize64
        
        // Get GPU Info using Metal
        gpuInfo.removeAll()
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Failed to get Metal device")
            return
        }
        
        let gpuName = device.name
        let isAppleSilicon = device.supportsFamily(.apple1)
        let architecture = isAppleSilicon ? "Apple Silicon" : "Intel"
        let gpuVRAM = device.recommendedMaxWorkingSetSize
        let gpuDescription = "\(gpuName) (\(architecture))"
        gpuInfo = [(type: gpuDescription, vram: UInt64(gpuVRAM))]
    }
    
    private func updateResourceUsage() {
        // Update CPU Usage
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            if let previous = previousCPULoad {
                let userDiff = Double(cpuLoad.cpu_ticks.0 - previous.cpu_ticks.0)
                let systemDiff = Double(cpuLoad.cpu_ticks.1 - previous.cpu_ticks.1)
                let idleDiff = Double(cpuLoad.cpu_ticks.2 - previous.cpu_ticks.2)
                let niceDiff = Double(cpuLoad.cpu_ticks.3 - previous.cpu_ticks.3)
                
                let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
                if totalTicks > 0 {
                    let usedTicks = userDiff + systemDiff + niceDiff
                    cpuUsage = (usedTicks / totalTicks) * 100.0
                }
            }
            previousCPULoad = cpuLoad
        }
        
        // Update Memory Usage using vm_statistics64
        let hostPort = mach_host_self()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var hostInfo = vm_statistics64_data_t()
        
        let ramResult = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }
        
        if ramResult == KERN_SUCCESS {
            // Calculate active memory (wired + active pages)
            let wiredMemory = UInt64(hostInfo.wire_count) * pageSize
            let activeMemory = UInt64(hostInfo.active_count) * pageSize
            
            // Update used memory
            usedMemory = wiredMemory + activeMemory
            
            // Calculate memory usage percentage
            memoryUsage = totalMemory > 0 ? (Double(usedMemory) / Double(totalMemory)) * 100.0 : 0.0
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func resourceUsageColor(_ usage: Double) -> Color {
        switch usage {
        case ..<50:
            return .green
        case ..<75:
            return .yellow
        default:
            return .red
        }
    }
}

// MARK: - Preview Provider
struct HardwarePreferences_Previews: PreviewProvider {
    static var previews: some View {
        HardwarePreferences()
    }
}
