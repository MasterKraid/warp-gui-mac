import SwiftUI

struct ToolsTabView: View {
    @ObservedObject var state: WarpState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sub-tool switcher
            Picker("", selection: $state.selectedSubTool) {
                ForEach(WarpState.SubTool.allCases) { tool in
                    Text(tool.rawValue).tag(tool)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            switch state.selectedSubTool {
            case .diagnostics:
                diagnosticsView
            case .daemon:
                daemonView
            case .logs:
                logsView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Diagnostics View

    private var diagnosticsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NETWORK DIAGNOSTICS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
                    .kerning(0.8)
                Spacer()
                Button(action: {
                    state.runDiagnostics()
                }) {
                    HStack(spacing: 5) {
                        if state.isRunningDiagnostics {
                            ProgressView().controlSize(.mini)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 8))
                        }
                        Text(state.isRunningDiagnostics ? "Testing..." : "Run Test")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(state.isRunningDiagnostics ? Color.secondary.opacity(0.3) : WarpTheme.orange)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(state.isRunningDiagnostics)
            }

            if state.diagnosticsText.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 24))
                        .foregroundColor(WarpTheme.orange.opacity(0.6))
                    Text("Run diagnostic checks to test route latency,\nreachability, and Cloudflare edge connectivity.")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    Text(state.diagnosticsText)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.primary.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 180)
            }
        }
    }

    // MARK: - Daemon View

    private var daemonView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SYSTEM SERVICE DAEMON")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.secondary.opacity(0.8))
                .kerning(0.8)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(state.daemonRunning ? WarpTheme.green.opacity(0.18) : Color.red.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: state.daemonRunning ? "gearshape.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(state.daemonRunning ? WarpTheme.green : .red)
                        .font(.system(size: 14))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.daemonRunning ? "Daemon Active" : "Daemon Stopped")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Text("com.cloudflare.1dot1dot1dot1.macos.warp.daemon")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    state.restartDaemon()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9, weight: .bold))
                        Text("Restart")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(WarpTheme.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WarpTheme.orangeDim)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text("Service Status:")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                Text("• Root daemon running in background via launchd\n• Controls WireGuard & MASQUE network extensions\n• Communicates via local IPC sockets")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineSpacing(2)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Logs View

    private var logsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SERVICE ACTIVITY LOGS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
                    .kerning(0.8)
                Spacer()
                Button(action: {
                    state.refreshLogs()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9))
                        .foregroundColor(WarpTheme.orange)
                }
                .buttonStyle(.plain)
                .help("Reload logs")
            }

            // Search filter
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                TextField("Filter log entries...", text: $state.logFilter)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, design: .rounded))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)

            // Log scroll
            ScrollView {
                let filtered = state.logFilter.isEmpty ? state.logs : state.logs.filter { $0.localizedCaseInsensitiveContains(state.logFilter) }
                LazyVStack(alignment: .leading, spacing: 2) {
                    if filtered.isEmpty {
                        Text("No logs matching filter.")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(8)
                    } else {
                        ForEach(Array(filtered.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(6)
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)
            .frame(maxHeight: 150)
        }
    }
}
