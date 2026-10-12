import SwiftUI

public struct MRCardView: View {
    public let mr: MergeRequestItem
    @ObservedObject var viewModel: MRTrackerViewModel
    @State private var isHovered: Bool = false
    @State private var copiedNotice: String? = nil

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            // Top Row: Author, Repo, Relative time
            HStack(alignment: .center, spacing: 6) {
                // Author Tag
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                    Text(mr.authorName)
                        .font(.system(size: 11, weight: .semibold))
                }

                Text("•")
                    .foregroundColor(.secondary)
                    .font(.system(size: 10))

                // Repo badge
                HStack(spacing: 3) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 9))
                    Text(mr.repoShortName)
                        .font(.system(size: 10, weight: .bold))
                    Text("!\(mr.iid)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(4)

                Spacer()

                // Staleness indicator
                HStack(spacing: 3) {
                    Image(systemName: mr.isStale ? "clock.badge.exclamationmark.fill" : "clock")
                        .font(.system(size: 9))
                        .foregroundColor(mr.isStale ? .red : .secondary)
                    Text(mr.timeAgo)
                        .font(.system(size: 10, weight: mr.isStale ? .bold : .regular))
                        .foregroundColor(mr.isStale ? .red : .secondary)
                }
            }

            // Title
            Text(mr.title)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Branches
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(mr.sourceBranch)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Image(systemName: "arrow.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Text(mr.targetBranch)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // Status Pills
            HStack(spacing: 5) {
                if mr.isDraft {
                    pill(text: "Draft", icon: "pencil", bg: .secondary.opacity(0.15), fg: .secondary)
                }

                if mr.hasConflicts {
                    pill(text: "Conflicts", icon: "exclamationmark.triangle.fill", bg: .red.opacity(0.18), fg: .red)
                }

                if mr.detailedMergeStatus == "need_rebase" {
                    pill(text: "Needs Rebase", icon: "arrow.triangle.swap", bg: .orange.opacity(0.18), fg: .orange)
                }

                if !mr.blockingDiscussionsResolved && mr.userNotesCount > 0 {
                    pill(text: "\(mr.userNotesCount) comments", icon: "bubble.left.and.bubble.right.fill", bg: .orange.opacity(0.18), fg: .orange)
                }

                if mr.isMergeReady {
                    pill(text: "Merge Ready", icon: "checkmark.circle.fill", bg: .green.opacity(0.18), fg: .green)
                } else if mr.detailedMergeStatus == "ci_still_running" {
                    pill(text: "CI Running", icon: "rays", bg: .blue.opacity(0.18), fg: .blue)
                } else if mr.detailedMergeStatus == "ci_must_pass" {
                    pill(text: "CI Failed", icon: "xmark.octagon.fill", bg: .red.opacity(0.18), fg: .red)
                }

                if mr.upvotes > 0 {
                    pill(text: "\(mr.upvotes) 👍", icon: nil, bg: .green.opacity(0.15), fg: .green)
                }

                if mr.taskCount > 0 {
                    pill(text: "\(mr.completedTaskCount)/\(mr.taskCount) tasks", icon: "checklist", bg: .secondary.opacity(0.12), fg: .secondary)
                }

                Spacer()
            }

            // Reviewers row (if any)
            if !mr.reviewers.isEmpty {
                HStack(spacing: 4) {
                    Text("Reviewers:")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    ForEach(mr.reviewers.prefix(3), id: \.id) { rev in
                        Text("@\(rev.username)")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(3)
                    }
                }
            }

            // Action Row
            HStack(spacing: 8) {
                // Open in browser
                Button(action: {
                    viewModel.openURL(mr.webUrl)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "safari")
                            .font(.system(size: 9))
                        Text("Open \(viewModel.config.platform.term)")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)

                // Copy branch (if available)
                if !mr.sourceBranch.isEmpty {
                    Button(action: {
                        viewModel.copyToClipboard(mr.sourceBranch)
                        showCopyNotice("Branch copied!")
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9))
                            Text("Branch")
                                .font(.system(size: 10))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }

                // Copy CLI checkout command (gh pr checkout / glab mr checkout)
                Button(action: {
                    let cmd = (viewModel.config.platform == .github)
                        ? "gh pr checkout \(mr.iid) -R \(mr.repoFullName)"
                        : "glab mr checkout \(mr.iid) -R \(mr.repoFullName)"
                    viewModel.copyToClipboard(cmd)
                    showCopyNotice("\(viewModel.config.platform.cliToolName) copied!")
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "terminal")
                            .font(.system(size: 9))
                        Text("\(viewModel.config.platform.cliToolName) checkout")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)

                if let notice = copiedNotice {
                    Text(notice)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                        .transition(.opacity)
                }

                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(mr.isBlocked ? Color.red.opacity(0.4) : (isHovered ? Color.accentColor.opacity(0.4) : Color.secondary.opacity(0.15)), lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func showCopyNotice(_ text: String) {
        withAnimation {
            copiedNotice = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                copiedNotice = nil
            }
        }
    }

    @ViewBuilder
    private func pill(text: String, icon: String?, bg: Color, fg: Color) -> some View {
        HStack(spacing: 3) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 8))
            }
            Text(text)
                .font(.system(size: 9, weight: .semibold))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(bg)
        .foregroundColor(fg)
        .cornerRadius(4)
    }
}
