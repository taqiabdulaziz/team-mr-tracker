import SwiftUI

public struct ContentView: View {
    @ObservedObject public var viewModel: MRTrackerViewModel

    public init(viewModel: MRTrackerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(viewModel: viewModel)

            // Team Members Horizontal Bar
            TeamFilterBar(viewModel: viewModel)

            // Category Bar (All, Blocked, Needs Review, Merge Ready, Drafts)
            StatusCategoryBar(viewModel: viewModel)

            Divider()
                .padding(.top, 4)

            // Main List
            MRListView(viewModel: viewModel)

            Divider()

            // Footer
            HStack {
                let repoSet = Set(viewModel.mergeRequests.map { $0.repoFullName })
                Text("\(viewModel.filteredMRs.count) \(viewModel.config.platform.term)s showing across \(repoSet.count) repositories")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()

                if viewModel.attentionCount > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.blockedCount > 0 ? Color.red : Color.orange)
                            .frame(width: 6, height: 6)
                        Text("\(viewModel.attentionCount) need action")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(viewModel.blockedCount > 0 ? .red : .orange)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 480, height: 600)
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .task {
            await viewModel.refresh()
        }
    }
}
