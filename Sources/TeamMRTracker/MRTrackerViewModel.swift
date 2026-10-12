import Foundation
import SwiftUI
import AppKit

@MainActor
public final class MRTrackerViewModel: ObservableObject {
    @Published public var config: AppConfig
    @Published public var mergeRequests: [MergeRequestItem] = []
    @Published public var selectedMemberUsername: String? = nil
    @Published public var selectedCategory: StatusCategory = .all
    @Published public var searchQuery: String = ""
    @Published public var isLoading: Bool = false
    @Published public var lastRefreshedAt: Date? = nil
    @Published public var errorMessage: String? = nil
    @Published public var showSettings: Bool = false

    private var refreshTimer: Timer?

    public init() {
        self.config = ConfigManager.shared.loadConfig()
        startAutoRefresh()
    }

    public func startAutoRefresh() {
        refreshTimer?.invalidate()
        let interval = max(1, config.refreshIntervalMinutes) * 60
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    public func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    public func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let items = await GitProviderService.shared.fetchTeamItems(config: config)
        self.mergeRequests = items
        self.lastRefreshedAt = Date()
        self.isLoading = false
    }

    public func updateConfig(_ newConfig: AppConfig) {
        self.config = newConfig
        ConfigManager.shared.saveConfig(newConfig)
        startAutoRefresh()
        Task {
            await refresh()
        }
    }

    public var attentionCount: Int {
        mergeRequests.filter { $0.isBlocked || $0.isNeedsReview }.count
    }

    public var blockedCount: Int {
        mergeRequests.filter { $0.isBlocked }.count
    }

    public var needsReviewCount: Int {
        mergeRequests.filter { $0.isNeedsReview }.count
    }

    public var mergeReadyCount: Int {
        mergeRequests.filter { $0.isMergeReady }.count
    }

    public var draftsCount: Int {
        mergeRequests.filter { $0.isDraft }.count
    }

    public func count(for memberUsername: String) -> Int {
        mergeRequests.filter { $0.authorUsername == memberUsername }.count
    }

    public func hasBlocked(for memberUsername: String) -> Bool {
        mergeRequests.contains { $0.authorUsername == memberUsername && $0.isBlocked }
    }

    public var filteredMRs: [MergeRequestItem] {
        return mergeRequests.filter { mr in
            // Exclude MRs without activity for more than maxInactiveDays
            if mr.daysSinceUpdate > config.maxInactiveDays {
                return false
            }

            // Filter by member
            if let selected = selectedMemberUsername, !selected.isEmpty {
                if mr.authorUsername != selected {
                    return false
                }
            }

            // Filter by category
            switch selectedCategory {
            case .all:
                break
            case .blocked:
                if !mr.isBlocked { return false }
            case .needsReview:
                if !mr.isNeedsReview { return false }
            case .mergeReady:
                if !mr.isMergeReady { return false }
            case .drafts:
                if !mr.isDraft { return false }
            }

            // Filter by search query
            let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !query.isEmpty {
                let matchTitle = mr.title.lowercased().contains(query)
                let matchRepo = mr.repoFullName.lowercased().contains(query)
                let matchAuthor = mr.authorName.lowercased().contains(query) || mr.authorUsername.lowercased().contains(query)
                let matchBranch = mr.sourceBranch.lowercased().contains(query)
                if !matchTitle && !matchRepo && !matchAuthor && !matchBranch {
                    return false
                }
            }

            return true
        }
    }

    public func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    public func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
