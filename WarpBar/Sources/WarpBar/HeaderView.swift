import SwiftUI

struct HeaderView: View {
    @ObservedObject var state: WarpState

    var body: some View {
        VStack(spacing: 14) {
            // Top Row: Logo, Title & Master Switch
            HStack(alignment: .center, spacing: 12) {
                // Cloudflare Cloud Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            state.isConnected
                            ? LinearGradient(colors: [WarpTheme.orange, WarpTheme.orangeLight], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.secondary.opacity(0.18), Color.secondary.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: state.isConnected ? WarpTheme.orangeGlow : Color.clear, radius: 6, x: 0, y: 2)

                    Image(systemName: "cloud.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 14)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Cloudflare WARP")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        Circle()
                            .fill(state.isConnected ? WarpTheme.green : Color.gray.opacity(0.5))
                            .frame(width: 7, height: 7)
                    }

                    Text(state.isConnecting ? "Connecting..." : (state.isConnected ? "Protected & Encrypted" : "Disconnected"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(state.isConnected ? WarpTheme.orange : .secondary)
                }

                Spacer()

                // Master Toggle with Cloudflare Orange Tint
                Toggle("", isOn: Binding(
                    get: { state.isConnected },
                    set: { _ in state.toggle() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: WarpTheme.orange))
                .labelsHidden()
                .disabled(state.isConnecting)
            }

            // Secondary Row: IP Capsule & Status Pill
            HStack(spacing: 8) {
                // IP Capsule
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(state.publicIP, forType: .string)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        state.copiedIP = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            state.copiedIP = false
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 11))
                            .foregroundColor(WarpTheme.orange)

                        Text(state.publicIP)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)

                        Image(systemName: state.copiedIP ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(state.copiedIP ? WarpTheme.green : .secondary.opacity(0.8))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Click to copy IP address")

                Spacer()

                // Network Health Badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(state.networkHealth == "Healthy" ? WarpTheme.green : (state.networkHealth == "Unstable" ? WarpTheme.orange : Color.gray))
                        .frame(width: 6, height: 6)

                    Text(state.networkHealth)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .clipShape(Capsule())

                // Refresh Button
                Button(action: {
                    Task {
                        await state.refreshAll()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Refresh Status")
            }

            // Notification / Status banner
            if let msg = state.statusMessage {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                    Text(msg)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(WarpTheme.orange)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(WarpTheme.orangeDim)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}
