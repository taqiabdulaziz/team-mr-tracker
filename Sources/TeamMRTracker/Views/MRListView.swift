import SwiftUI

public struct MRListView: View {
    @ObservedObject var viewModel: MRTrackerViewModel

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if let err = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 13))
                            Text("Connection & Sync Issue")
                                .font(.system(size: 12, weight: .bold))
                            Spacer()
                        }

                        Text(err)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            Button("Preferences (⚙)") {
                                viewModel.showSettings = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                            Button("Retry Sync") {
                                Task {
                                    await viewModel.refresh()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                    )
                }

                if viewModel.isLoading && viewModel.mergeRequests.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Syncing team \(viewModel.config.platform.term)s from \(viewModel.config.platform.rawValue)...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if viewModel.filteredMRs.isEmpty && viewModel.errorMessage == nil {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        Text(emptyMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        if viewModel.selectedCategory != .all || viewModel.selectedMemberUsername != nil {
                            Button("Reset Filters") {
                                viewModel.selectedCategory = .all
                                viewModel.selectedMemberUsername = nil
                                viewModel.searchQuery = ""
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.filteredMRs) { mr in
                        MRCardView(mr: mr, viewModel: viewModel)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
    }

    private var emptyMessage: String {
        let term = viewModel.config.platform.term
        if !viewModel.searchQuery.isEmpty {
            return "No \(term)s match \"\(viewModel.searchQuery)\""
        }
        if viewModel.selectedCategory == .blocked {
            return "No blocked \(term)s! Everything is clear."
        }
        if viewModel.selectedCategory == .needsReview {
            return "No \(term)s waiting for review."
        }
        if viewModel.selectedCategory == .mergeReady {
            return "No \(term)s currently ready to merge."
        }
        if let member = viewModel.selectedMemberUsername {
            return "No open \(term)s for @\(member)."
        }
        return "No open \(term)s found across team members."
    }
}
