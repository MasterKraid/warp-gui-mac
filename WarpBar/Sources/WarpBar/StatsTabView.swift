import SwiftUI

struct StatsTabView: View {
    @ObservedObject var state: WarpState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("NETWORK & PERFORMANCE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
                    .kerning(0.8)

                Spacer()

                Button(action: {
                    state.refreshStats()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9))
                        Text("Refresh")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(WarpTheme.orange)
            }

            // Highlights Grid
            let parsed = parseStats(state.statsText)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatCard(title: "Status", value: state.isConnected ? "Protected" : "Offline", icon: "shield.fill", color: state.isConnected ? WarpTheme.green : .secondary)
                StatCard(title: "Health", value: state.networkHealth, icon: "waveform.path.ecg", color: WarpTheme.orange)
                StatCard(title: "DNS Queries", value: parsed.dnsQueries, icon: "arrow.up.arrow.down", color: WarpTheme.orange)
                StatCard(title: "Avg Latency", value: parsed.dnsLatency, icon: "timer", color: WarpTheme.orange)
            }

            // Raw Output Toggle & ScrollView
            HStack {
                Button(action: {
                    withAnimation {
                        state.showRawStats.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: state.showRawStats ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9))
                        Text(state.showRawStats ? "Hide Raw Metrics" : "Show Full CLI Metrics")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.top, 4)

            if state.showRawStats {
                ScrollView {
                    Text(state.statsText)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.primary.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 140)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onAppear {
            state.refreshStats()
        }
    }

    private func parseStats(_ text: String) -> (dnsQueries: String, dnsLatency: String) {
        var queries = "-"
        var latency = "-"

        let lines = text.components(separatedBy: .newlines)
        for (i, line) in lines.enumerated() {
            if line.contains("dns_proxy") && line.contains("path=lookup") {
                if i + 1 < lines.count {
                    let next = lines[i + 1]
                    if let range = next.range(of: "doh_avg_ms") {
                        let sub = next[range.upperBound...]
                        if let avgRange = sub.range(of: "avg = ") {
                            let valStr = sub[avgRange.upperBound...].components(separatedBy: ")")[0]
                            if let val = Double(valStr.trimmingCharacters(in: .whitespaces)) {
                                latency = String(format: "%.1f ms", val)
                            }
                        }
                        if let countRange = sub.range(of: "count = ") {
                            let countStr = sub[countRange.upperBound...].components(separatedBy: ",")[0]
                            queries = countStr.trimmingCharacters(in: .whitespaces)
                        }
                    }
                }
            }
        }

        return (queries, latency)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = WarpTheme.orange

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}
