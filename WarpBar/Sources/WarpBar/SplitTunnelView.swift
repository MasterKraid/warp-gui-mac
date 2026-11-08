import SwiftUI

struct SplitTunnelView: View {
    @ObservedObject var state: WarpState

    var filteredExclusions: [ExcludedItem] {
        if state.exclusionFilter.isEmpty {
            return state.exclusions
        } else {
            return state.exclusions.filter { $0.value.localizedCaseInsensitiveContains(state.exclusionFilter) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("SPLIT TUNNEL EXCLUSIONS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
                    .kerning(0.8)
                Spacer()
                Text("\(state.exclusions.count) routes")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(WarpTheme.orange)
            }

            // Input Bar
            HStack(spacing: 8) {
                TextField("Domain or IP (e.g. example.com)", text: $state.newExclusionTarget)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 11, design: .rounded))
                    .onSubmit {
                        submitNewTarget()
                    }

                Button(action: submitNewTarget) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Add")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(state.newExclusionTarget.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.3) : WarpTheme.orange)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(state.newExclusionTarget.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Search Filter
            if state.exclusions.count > 5 {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    TextField("Filter exclusions...", text: $state.exclusionFilter)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .rounded))
                    if !state.exclusionFilter.isEmpty {
                        Button(action: { state.exclusionFilter = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(6)
            }

            // Exclusions List
            ScrollView {
                LazyVStack(spacing: 4) {
                    if filteredExclusions.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text(state.exclusions.isEmpty ? "All traffic is routed through WARP.\nAdd specific domains or IPs to bypass the tunnel." : "No matching routes found.")
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(filteredExclusions) { item in
                            HStack(spacing: 8) {
                                Image(systemName: item.isIP ? "number" : "globe")
                                    .font(.system(size: 10))
                                    .foregroundColor(WarpTheme.orange)
                                    .frame(width: 14)

                                Text(item.value)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Spacer()

                                Button(action: {
                                    state.removeExclusion(item.value)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary.opacity(0.7))
                                        .padding(4)
                                        .background(Color.white.opacity(0.04))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .help("Remove from split tunnel")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.35))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func submitNewTarget() {
        let trimmed = state.newExclusionTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            state.addExclusion(trimmed)
            state.newExclusionTarget = ""
        }
    }
}
