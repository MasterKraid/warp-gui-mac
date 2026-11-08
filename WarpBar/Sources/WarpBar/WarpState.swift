import Foundation
import Combine
import SwiftUI

@MainActor
final class WarpState: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var publicIP: String = "Detecting..."
    @Published var networkHealth: String = "Unknown"
    @Published var rawStatus: String = ""
    @Published var currentMode: String = "warp"
    @Published var daemonRunning: Bool = true
    @Published var exclusions: [ExcludedItem] = []
    @Published var statsText: String = "No stats available yet"
    @Published var diagnosticsText: String = ""
    @Published var isRunningDiagnostics: Bool = false
    @Published var logs: [String] = []
    @Published var statusMessage: String? = nil
    @Published var selectedTab: WarpTab = .status
    @Published var launchAtLogin: Bool = false
    
    // UI Local State without @State macro requirement
    @Published var copiedIP: Bool = false
    @Published var selectedFamily: String = "off"
    @Published var newExclusionTarget: String = ""
    @Published var exclusionFilter: String = ""
    @Published var showRawStats: Bool = false
    @Published var selectedSubTool: SubTool = .diagnostics
    @Published var logFilter: String = ""

    enum SubTool: String, CaseIterable, Identifiable {
        case diagnostics = "Diagnostics"
        case daemon = "Daemon"
        case logs = "Logs"
        var id: String { rawValue }
    }
    
    private var timer: AnyCancellable?
    private let bridge = CLIBridge.shared

    enum WarpTab: String, CaseIterable, Identifiable {
        case status = "Status"
        case splitTunnel = "Exclusions"
        case stats = "Stats"
        case tools = "Tools & Logs"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .status: return "shield.lefthalf.filled"
            case .splitTunnel: return "arrow.triangle.branch"
            case .stats: return "chart.xyaxis.line"
            case .tools: return "wrench.and.screwdriver"
            }
        }
    }

    init() {
        checkLaunchAtLogin()
        startPolling()
        Task {
            await refreshAll()
        }
    }

    func startPolling() {
        timer = Timer.publish(every: 3.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.quickRefresh()
                }
            }
    }

    func quickRefresh() async {
        let status = await bridge.getStatus()
        self.isConnected = status.connected
        if let ip = status.ip, !ip.isEmpty {
            self.publicIP = ip
        }
        self.networkHealth = status.networkHealth
        self.rawStatus = status.raw
        self.daemonRunning = await bridge.isDaemonRunning()
    }

    func refreshAll() async {
        await quickRefresh()
        self.currentMode = await bridge.getCurrentMode()
        self.exclusions = await bridge.getExclusions()
        self.logs = await bridge.getRecentLogs(maxLines: 80)
    }

    // MARK: - Actions

    func toggle() {
        isConnecting = true
        statusMessage = isConnected ? "Disconnecting..." : "Connecting..."
        Task {
            _ = await bridge.toggleConnection()
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await self.refreshAll()
            self.isConnecting = false
            self.statusMessage = self.isConnected ? "Connected to WARP" : "Disconnected"
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if self.statusMessage == "Connected to WARP" || self.statusMessage == "Disconnected" {
                self.statusMessage = nil
            }
        }
    }

    func connect() {
        isConnecting = true
        statusMessage = "Connecting to WARP..."
        Task {
            _ = await bridge.connect()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await self.refreshAll()
            self.isConnecting = false
            self.statusMessage = self.isConnected ? "Connected to WARP" : "Connection failed"
        }
    }

    func disconnect() {
        isConnecting = true
        statusMessage = "Disconnecting..."
        Task {
            _ = await bridge.disconnect()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await self.refreshAll()
            self.isConnecting = false
            self.statusMessage = "Disconnected"
        }
    }

    func switchMode(to mode: String) {
        statusMessage = "Switching mode to \(mode)..."
        Task {
            let res = await bridge.setMode(mode)
            if res.success {
                self.currentMode = mode
                self.statusMessage = "Mode updated: \(mode)"
            } else {
                self.statusMessage = "Mode error: \(res.message)"
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = nil
        }
    }

    func addExclusion(_ target: String) {
        statusMessage = "Adding exclusion..."
        Task {
            let res = await bridge.addExclusion(target)
            if res.success {
                self.exclusions = await bridge.getExclusions()
                self.statusMessage = "Added \(target)"
            } else {
                self.statusMessage = "Error: \(res.message)"
            }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            self.statusMessage = nil
        }
    }

    func removeExclusion(_ target: String) {
        statusMessage = "Removing exclusion..."
        Task {
            let res = await bridge.removeExclusion(target)
            if res.success {
                self.exclusions.removeAll { $0.value == target }
                self.statusMessage = "Removed \(target)"
            } else {
                self.statusMessage = "Error: \(res.message)"
            }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            self.statusMessage = nil
        }
    }

    func refreshStats() {
        Task {
            let text = await bridge.getStats()
            self.statsText = text.isEmpty ? "No active connection statistics." : text
        }
    }

    func runDiagnostics() {
        isRunningDiagnostics = true
        diagnosticsText = "Running diagnostics (testing network, DNS, and latency)..."
        Task {
            let result = await bridge.runDiagnostics()
            self.diagnosticsText = result
            self.isRunningDiagnostics = false
        }
    }

    func restartDaemon() {
        statusMessage = "Restarting WARP daemon..."
        Task {
            _ = await bridge.restartDaemon()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await self.refreshAll()
            self.statusMessage = self.daemonRunning ? "Daemon restarted" : "Daemon restarted"
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = nil
        }
    }

    func refreshLogs() {
        Task {
            self.logs = await bridge.getRecentLogs(maxLines: 80)
        }
    }

    func setFamiliesMode(_ mode: String) {
        statusMessage = "Updating 1.1.1.1 Families..."
        Task {
            _ = await bridge.setFamiliesMode(mode)
            self.statusMessage = "Families mode: \(mode)"
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.statusMessage = nil
        }
    }

    // MARK: - Launch at Login

    private func checkLaunchAtLogin() {
        let script = "tell application \"System Events\" to get name of every login item"
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            self.launchAtLogin = output.contains("WarpBar")
        }
    }

    func toggleLaunchAtLogin(_ enable: Bool) {
        self.launchAtLogin = enable
        let appPath = Bundle.main.bundlePath
        let script: String
        if enable {
            script = "tell application \"System Events\" to make login item at end with properties {path:\"\(appPath)\", hidden:false, name:\"WarpBar\"}"
        } else {
            script = "tell application \"System Events\" to delete (every login item whose name is \"WarpBar\")"
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }
}
