import Foundation

struct WarpStatusInfo: Codable {
    var connected: Bool = false
    var ip: String? = nil
    var raw: String = ""
    var networkHealth: String = "unknown"
}

struct ExcludedItem: Identifiable, Hashable {
    let id: String
    let value: String
    let isIP: Bool
    
    init(_ value: String) {
        self.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = self.value
        let parts = self.value.split(separator: ".")
        self.isIP = (parts.count == 4 && parts.allSatisfy { Int($0) != nil }) || self.value.contains(":") || self.value.contains("/")
    }
}

actor CLIBridge {
    static let shared = CLIBridge()

    private let preferredPaths: [String] = [
        "/opt/homebrew/bin/warp",
        "/usr/local/bin/warp",
        "/usr/local/bin/warp-cli",
        "/opt/homebrew/bin/warp-cli",
        "/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli"
    ]

    private func findBinary(named name: String) -> String? {
        for path in preferredPaths {
            if path.hasSuffix("/" + name) && FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        let which = Process()
        let pipe = Pipe()
        which.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        which.arguments = [name]
        which.standardOutput = pipe
        which.environment = [
            "PATH": "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        ]
        
        do {
            try which.run()
            which.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty, FileManager.default.isExecutableFile(atPath: output) {
                return output
            }
        } catch {}
        
        return nil
    }

    func execute(binary: String, args: [String]) async -> (output: String, error: String, exitCode: Int32) {
        guard let binPath = findBinary(named: binary) else {
            return ("", "Binary '\(binary)' not found in PATH", 127)
        }

        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: binPath)
        process.arguments = args
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.environment = [
            "PATH": "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "HOME": NSHomeDirectory(),
            "USER": NSUserName()
        ]

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try process.run()
                    process.waitUntilExit()

                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

                    let outStr = String(data: outData, encoding: .utf8) ?? ""
                    let errStr = String(data: errData, encoding: .utf8) ?? ""

                    continuation.resume(returning: (outStr, errStr, process.terminationStatus))
                } catch {
                    continuation.resume(returning: ("", error.localizedDescription, -1))
                }
            }
        }
    }

    // MARK: - Core Operations

    func getStatus() async -> WarpStatusInfo {
        var info = WarpStatusInfo()
        
        // 1. Try warp status --json first
        let warpResult = await execute(binary: "warp", args: ["status", "--json"])
        if warpResult.exitCode == 0, let data = warpResult.output.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode(WarpStatusInfo.self, from: data) {
                info = decoded
            }
        }

        // 2. Fallback / supplement with warp-cli status
        if info.raw.isEmpty {
            let cliResult = await execute(binary: "warp-cli", args: ["status"])
            info.raw = cliResult.output
            info.connected = cliResult.output.contains("Connected")
        }

        // Extract Network health if present in raw
        if info.raw.contains("Network: healthy") {
            info.networkHealth = "Healthy"
        } else if info.raw.contains("Network: unstable") {
            info.networkHealth = "Unstable"
        } else if info.raw.contains("Network: unavailable") {
            info.networkHealth = "Unavailable"
        } else if info.connected {
            info.networkHealth = "Active"
        } else {
            info.networkHealth = "Inactive"
        }

        // 3. Fallback IP fetch if missing
        if info.ip == nil || info.ip?.isEmpty == true {
            info.ip = await fetchPublicIP()
        }

        return info
    }

    func toggleConnection() async -> Bool {
        let result = await execute(binary: "warp", args: ["toggle"])
        return result.exitCode == 0
    }

    func connect() async -> Bool {
        let result = await execute(binary: "warp", args: ["up"])
        if result.exitCode != 0 {
            let cliResult = await execute(binary: "warp-cli", args: ["connect"])
            return cliResult.exitCode == 0
        }
        return true
    }

    func disconnect() async -> Bool {
        let result = await execute(binary: "warp", args: ["down"])
        if result.exitCode != 0 {
            let cliResult = await execute(binary: "warp-cli", args: ["disconnect"])
            return cliResult.exitCode == 0
        }
        return true
    }

    // MARK: - Mode Management

    func getCurrentMode() async -> String {
        let result = await execute(binary: "warp-cli", args: ["settings", "list"])
        let lines = result.output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("Mode:") {
                let parts = line.components(separatedBy: "Mode:")
                if parts.count > 1 {
                    return parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return "warp"
    }

    func setMode(_ mode: String) async -> (success: Bool, message: String) {
        let result = await execute(binary: "warp-cli", args: ["mode", mode])
        if result.exitCode == 0 {
            return (true, "Mode switched to \(mode)")
        } else {
            return (false, result.error.isEmpty ? result.output : result.error)
        }
    }

    // MARK: - Split Tunnel (Exclude)

    func getExclusions() async -> [ExcludedItem] {
        let result = await execute(binary: "warp", args: ["exclude", "list"])
        var items: [ExcludedItem] = []

        if result.exitCode == 0 {
            let lines = result.output.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !trimmed.hasPrefix("Excluded:") {
                    items.append(ExcludedItem(trimmed))
                }
            }
        }

        if items.isEmpty {
            let cliResult = await execute(binary: "warp-cli", args: ["tunnel", "dump"])
            let lines = cliResult.output.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !trimmed.hasPrefix("Excluded:") && !trimmed.hasPrefix("Merged") {
                    items.append(ExcludedItem(trimmed))
                }
            }
        }

        return items
    }

    func addExclusion(_ target: String) async -> (success: Bool, message: String) {
        let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (false, "Target cannot be empty") }

        let result = await execute(binary: "warp", args: ["exclude", "add", trimmed])
        if result.exitCode == 0 {
            return (true, "Added '\(trimmed)' to split tunnel")
        } else {
            return (false, result.error.isEmpty ? result.output : result.error)
        }
    }

    func removeExclusion(_ target: String) async -> (success: Bool, message: String) {
        let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (false, "Target cannot be empty") }

        let result = await execute(binary: "warp", args: ["exclude", "remove", trimmed])
        if result.exitCode == 0 {
            return (true, "Removed '\(trimmed)' from split tunnel")
        } else {
            return (false, result.error.isEmpty ? result.output : result.error)
        }
    }

    // MARK: - Stats & Diagnostics

    func getStats() async -> String {
        let result = await execute(binary: "warp", args: ["stats"])
        if result.exitCode == 0 && !result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return result.output
        }
        let cliResult = await execute(binary: "warp-cli", args: ["stats"])
        return cliResult.output
    }

    func runDiagnostics() async -> String {
        let result = await execute(binary: "warp", args: ["diagnose"])
        if result.exitCode == 0 && !result.output.isEmpty {
            return result.output
        }
        let cliResult = await execute(binary: "warp-cli", args: ["debug", "network"])
        return cliResult.output
    }

    // MARK: - Daemon Control

    func isDaemonRunning() async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", "CloudflareWARP"]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    func restartDaemon() async -> Bool {
        let stop = await execute(binary: "warp", args: ["daemon", "restart"])
        if stop.exitCode == 0 { return true }

        let killProc = Process()
        killProc.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        killProc.arguments = ["launchctl", "kickstart", "-k", "system/com.cloudflare.1dot1dot1dot1.macos.warp.daemon"]
        do {
            try killProc.run()
            killProc.waitUntilExit()
            return killProc.terminationStatus == 0
        } catch {
            return false
        }
    }

    // MARK: - Logs

    func getRecentLogs(maxLines: Int = 100) -> [String] {
        let logPath = "/Library/Application Support/Cloudflare/cfwarp_service_log.txt"
        guard FileManager.default.fileExists(atPath: logPath),
              let content = try? String(contentsOfFile: logPath, encoding: .utf8) else {
            return ["Log file not accessible or empty."]
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if lines.count <= maxLines {
            return lines
        } else {
            return Array(lines.suffix(maxLines))
        }
    }

    // MARK: - Families Mode (DNS 1.1.1.1)

    func setFamiliesMode(_ mode: String) async -> Bool {
        let result = await execute(binary: "warp-cli", args: ["dns", "families", mode])
        return result.exitCode == 0
    }

    // MARK: - IP Helper

    private func fetchPublicIP() async -> String? {
        guard let url = URL(string: "https://api.ipify.org") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
