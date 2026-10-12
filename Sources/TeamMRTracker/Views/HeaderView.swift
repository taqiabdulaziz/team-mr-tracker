import SwiftUI

public struct HeaderView: View {
    @ObservedObject var viewModel: MRTrackerViewModel

    public var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.config.platform.iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.config.platform == .gitlab ? .orange : .purple)
                    Text("Team \(viewModel.config.platform.term) Tracker")
                        .font(.system(size: 14, weight: .semibold))
                }

                Spacer()

                if let last = viewModel.lastRefreshedAt {
                    Text(timeAgo(from: last))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                // Refresh Button
                Button(action: {
                    Task {
                        await viewModel.refresh()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                }
                .buttonStyle(.plain)
                .help("Refresh MRs now (⌘R)")
                .disabled(viewModel.isLoading)

                // Settings Button
                Button(action: {
                    viewModel.showSettings.toggle()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .help("Preferences & Team Members")

                // Quit Button
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit Team MR Tracker")
            }

            // Search Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField("Filter by title, repo, branch, or author...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func timeAgo(from date: Date) -> String {
        let sec = Int(Date().timeIntervalSince(date))
        if sec < 60 { return "Synced just now" }
        let min = sec / 60
        return "Synced \(min)m ago"
    }
}
