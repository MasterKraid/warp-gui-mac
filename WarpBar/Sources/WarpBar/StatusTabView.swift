import SwiftUI

struct StatusTabView: View {
    @ObservedObject var state: WarpState

    struct ModeItem: Identifiable {
        let id: String
        let title: String
        let desc: String
        let icon: String
    }

    let modes: [ModeItem] = [
        ModeItem(id: "warp", title: "WARP", desc: "Full VPN encryption with fast DNS", icon: "shield.fill"),
        ModeItem(id: "doh", title: "DoH (1.1.1.1)", desc: "Private DNS over HTTPS only", icon: "lock.shield.fill"),
        ModeItem(id: "warp+doh", title: "WARP + DoH", desc: "Full VPN tunnel with encrypted DoH", icon: "bolt.shield.fill"),
        ModeItem(id: "proxy", title: "SOCKS5 Proxy", desc: "Local proxy routing on 127.0.0.1", icon: "network"),
        ModeItem(id: "tunnel_only", title: "Tunnel Only", desc: "Direct VPN tunnel without DNS proxy", icon: "arrow.triangle.swap")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Modes Section
            VStack(alignment: .leading, spacing: 6) {
                Text("CONNECTION MODE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
                    .kerning(0.8)

                VStack(spacing: 4) {
                    ForEach(modes) { mode in
                        let isSelected = state.currentMode.lowercased().contains(mode.id.lowercased()) || (mode.id == "warp" && state.currentMode.lowercased() == "warpwithdnsoverhttps" && !state.currentMode.contains("Doh"))

                        Button(action: {
                            state.switchMode(to: mode.id)
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? WarpTheme.orange.opacity(0.2) : Color.white.opacity(0.04))
                                        .frame(width: 24, height: 24)

                                    Image(systemName: mode.icon)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(isSelected ? WarpTheme.orange : .secondary)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(mode.title)
                                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium, design: .rounded))
                                        .foregroundColor(isSelected ? .primary : .secondary)

                                    Text(mode.desc)
                                        .font(.system(size: 10, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary.opacity(0.8))
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(WarpTheme.orange)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isSelected ? WarpTheme.cardSelected : Color.white.opacity(0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(isSelected ? WarpTheme.cardSelectedBorder : Color.clear, lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .cornerRadius(10)
            }

            // Families Protection Mode
            VStack(alignment: .leading, spacing: 6) {
                Text("1.1.1.1 CONTENT FILTERING")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
                    .kerning(0.8)

                HStack(spacing: 8) {
                    FamilyPill(
                        title: "Standard",
                        desc: "No filter",
                        icon: "globe",
                        isSelected: state.selectedFamily == "off"
                    ) {
                        state.selectedFamily = "off"
                        state.setFamiliesMode("off")
                    }

                    FamilyPill(
                        title: "Malware",
                        desc: "Block threats",
                        icon: "shield.slash.fill",
                        isSelected: state.selectedFamily == "malware"
                    ) {
                        state.selectedFamily = "malware"
                        state.setFamiliesMode("malware")
                    }

                    FamilyPill(
                        title: "Families",
                        desc: "Adult + threats",
                        icon: "person.2.fill",
                        isSelected: state.selectedFamily == "full"
                    ) {
                        state.selectedFamily = "full"
                        state.setFamiliesMode("full")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct FamilyPill: View {
    let title: String
    let desc: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 9))
                    Text(title)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                }
                .foregroundColor(isSelected ? WarpTheme.orange : .primary)

                Text(desc)
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? WarpTheme.orangeDim : Color(NSColor.controlBackgroundColor).opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? WarpTheme.orange.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
