import SwiftUI

struct MainContentView: View {
    @ObservedObject var state: WarpState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(state: state)

            Divider()
                .opacity(0.4)

            // Polished Segmented Tab Bar
            HStack(spacing: 6) {
                ForEach(WarpState.WarpTab.allCases) { tab in
                    let isSelected = state.selectedTab == tab
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            state.selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .medium, design: .rounded))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(isSelected ? WarpTheme.orangeDim : Color.clear)
                        .foregroundColor(isSelected ? WarpTheme.orange : .secondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(isSelected ? WarpTheme.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.3))

            Divider()
                .opacity(0.4)

            // Active Tab Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    switch state.selectedTab {
                    case .status:
                        StatusTabView(state: state)
                    case .splitTunnel:
                        SplitTunnelView(state: state)
                    case .stats:
                        StatsTabView(state: state)
                    case .tools:
                        ToolsTabView(state: state)
                    }
                }
                .padding(.bottom, 12)
            }
            .frame(height: 335)
        }
        .frame(width: 360)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
