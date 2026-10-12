import Foundation

public enum GitPlatform: String, CaseIterable, Codable, Identifiable, Sendable {
    case gitlab = "GitLab"
    case github = "GitHub"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .gitlab: return "arrow.triangle.pull"
        case .github: return "chevron.left.forwardslash.chevron.right"
        }
    }

    public var term: String {
        switch self {
        case .gitlab: return "MR"
        case .github: return "PR"
        }
    }

    public var groupLabel: String {
        switch self {
        case .gitlab: return "Group / Namespace"
        case .github: return "Organization / Owner"
        }
    }

    public var cliToolName: String {
        switch self {
        case .gitlab: return "glab"
        case .github: return "gh"
        }
    }
}

public enum AuthMethod: String, CaseIterable, Codable, Identifiable, Sendable {
    case cli = "CLI Tool"
    case token = "Personal Access Token"

    public var id: String { rawValue }
}

public struct TeamMember: Identifiable, Codable, Hashable, Sendable {
    public var id: String { username }
    public var username: String
    public var displayName: String
    public var avatarUrl: String?

    public init(username: String, displayName: String, avatarUrl: String? = nil) {
        self.username = username
        self.displayName = displayName
        self.avatarUrl = avatarUrl
    }
}

// MARK: - GitLab Decodables

public struct GitLabAuthor: Codable, Hashable, Sendable {
    public let id: Int
    public let username: String
    public let name: String
    public let avatar_url: String?
}

public struct GitLabReviewer: Codable, Hashable, Sendable {
    public let id: Int
    public let username: String
    public let name: String
    public let avatar_url: String?
}

public struct GitLabReferences: Codable, Hashable, Sendable {
    public let short: String?
    public let relative: String?
    public let full: String?
}

public struct GitLabTaskStatus: Codable, Hashable, Sendable {
    public let count: Int?
    public let completed_count: Int?
}

public struct GitLabMRResponse: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let iid: Int
    public let project_id: Int
    public let title: String
    public let description: String?
    public let state: String
    public let created_at: String
    public let updated_at: String
    public let target_branch: String?
    public let source_branch: String?
    public let user_notes_count: Int?
    public let upvotes: Int?
    public let downvotes: Int?
    public let author: GitLabAuthor
    public let reviewers: [GitLabReviewer]?
    public let draft: Bool?
    public let work_in_progress: Bool?
    public let merge_status: String?
    public let detailed_merge_status: String?
    public let references: GitLabReferences?
    public let web_url: String
    public let has_conflicts: Bool?
    public let blocking_discussions_resolved: Bool?
    public let task_completion_status: GitLabTaskStatus?
}

// MARK: - GitHub Decodables

public struct GitHubSearchResponse: Codable, Sendable {
    public let total_count: Int
    public let items: [GitHubPRItem]
}

public struct GitHubUser: Codable, Sendable {
    public let login: String
    public let id: Int
    public let avatar_url: String?
}

public struct GitHubPRItem: Codable, Sendable {
    public let id: Int
    public let number: Int
    public let title: String
    public let html_url: String
    public let repository_url: String
    public let user: GitHubUser
    public let draft: Bool?
    public let state: String
    public let comments: Int?
    public let created_at: String
    public let updated_at: String
}

// MARK: - Status Categories

public enum StatusCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case blocked = "Blocked"
    case needsReview = "Needs Review"
    case mergeReady = "Merge Ready"
    case drafts = "Drafts"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .all: return "tray.full"
        case .blocked: return "exclamationmark.octagon.fill"
        case .needsReview: return "person.crop.circle.badge.clock"
        case .mergeReady: return "checkmark.seal.fill"
        case .drafts: return "pencil.and.outline"
        }
    }
}

// MARK: - Unified Pull/Merge Request Item

public struct MergeRequestItem: Identifiable, Hashable, Sendable {
    public let id: Int
    public let iid: Int
    public let title: String
    public let webUrl: URL
    public let repoFullName: String
    public let repoShortName: String
    public let authorUsername: String
    public let authorName: String
    public let authorAvatarUrl: URL?
    public let targetBranch: String
    public let sourceBranch: String
    public let userNotesCount: Int
    public let upvotes: Int
    public let reviewers: [GitLabReviewer]
    public let isDraft: Bool
    public let hasConflicts: Bool
    public let detailedMergeStatus: String
    public let blockingDiscussionsResolved: Bool
    public let taskCount: Int
    public let completedTaskCount: Int
    public let createdAt: Date
    public let updatedAt: Date

    public init(from raw: GitLabMRResponse) {
        self.id = raw.id
        self.iid = raw.iid
        self.title = raw.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.webUrl = URL(string: raw.web_url) ?? URL(string: "https://gitlab.com")!
        
        let fullRef = raw.references?.full ?? "repo!\(raw.iid)"
        self.repoFullName = fullRef.components(separatedBy: "!").first ?? "Unknown Repo"
        self.repoShortName = self.repoFullName.components(separatedBy: "/").last ?? self.repoFullName

        self.authorUsername = raw.author.username
        self.authorName = raw.author.name
        self.authorAvatarUrl = raw.author.avatar_url.flatMap { URL(string: $0) }

        self.targetBranch = raw.target_branch ?? "main"
        self.sourceBranch = raw.source_branch ?? ""
        self.userNotesCount = raw.user_notes_count ?? 0
        self.upvotes = raw.upvotes ?? 0
        self.reviewers = raw.reviewers ?? []

        self.isDraft = (raw.draft == true) || (raw.work_in_progress == true)
        self.hasConflicts = raw.has_conflicts ?? false
        self.detailedMergeStatus = raw.detailed_merge_status ?? raw.merge_status ?? "unknown"
        self.blockingDiscussionsResolved = raw.blocking_discussions_resolved ?? true

        self.taskCount = raw.task_completion_status?.count ?? 0
        self.completedTaskCount = raw.task_completion_status?.completed_count ?? 0

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var created = formatter.date(from: raw.created_at)
        var updated = formatter.date(from: raw.updated_at)
        if created == nil {
            formatter.formatOptions = [.withInternetDateTime]
            created = formatter.date(from: raw.created_at)
        }
        if updated == nil {
            formatter.formatOptions = [.withInternetDateTime]
            updated = formatter.date(from: raw.updated_at)
        }

        self.createdAt = created ?? Date()
        self.updatedAt = updated ?? Date()
    }

    public init(from gh: GitHubPRItem) {
        self.id = gh.id
        self.iid = gh.number
        self.title = gh.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.webUrl = URL(string: gh.html_url) ?? URL(string: "https://github.com")!

        let parts = gh.repository_url.components(separatedBy: "/repos/")
        let repoPath = parts.count > 1 ? parts[1] : "repository"
        self.repoFullName = repoPath
        self.repoShortName = repoPath.components(separatedBy: "/").last ?? repoPath

        self.authorUsername = gh.user.login
        self.authorName = gh.user.login
        self.authorAvatarUrl = gh.user.avatar_url.flatMap { URL(string: $0) }

        self.targetBranch = "default"
        self.sourceBranch = ""
        self.userNotesCount = gh.comments ?? 0
        self.upvotes = 0
        self.reviewers = []

        self.isDraft = gh.draft ?? false
        self.hasConflicts = false
        self.detailedMergeStatus = (gh.draft == true) ? "draft_status" : "needs_review"
        self.blockingDiscussionsResolved = true

        self.taskCount = 0
        self.completedTaskCount = 0

        let formatter = ISO8601DateFormatter()
        self.createdAt = formatter.date(from: gh.created_at) ?? Date()
        self.updatedAt = formatter.date(from: gh.updated_at) ?? Date()
    }

    public var isBlocked: Bool {
        if hasConflicts { return true }
        if detailedMergeStatus == "conflict" || detailedMergeStatus == "need_rebase" { return true }
        if detailedMergeStatus == "ci_must_pass" || detailedMergeStatus == "failed" { return true }
        if !blockingDiscussionsResolved && userNotesCount > 0 && !isDraft { return true }
        return false
    }

    public var isMergeReady: Bool {
        guard !isDraft && !isBlocked else { return false }
        return detailedMergeStatus == "mergeable" || (upvotes >= 2 && blockingDiscussionsResolved)
    }

    public var isNeedsReview: Bool {
        guard !isDraft && !isBlocked && !isMergeReady else { return false }
        return true
    }

    public var category: StatusCategory {
        if isDraft { return .drafts }
        if isBlocked { return .blocked }
        if isMergeReady { return .mergeReady }
        return .needsReview
    }

    public var isStale: Bool {
        let hours = Date().timeIntervalSince(updatedAt) / 3600
        return hours >= 48
    }

    public var timeAgo: String {
        let seconds = Int(Date().timeIntervalSince(updatedAt))
        if seconds < 60 { return "Just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }

    public var daysSinceUpdate: Int {
        let seconds = Date().timeIntervalSince(updatedAt)
        return max(0, Int(seconds / 86400))
    }
}

// MARK: - Portable App Configuration

public struct AppConfig: Codable, Sendable {
    public var platform: GitPlatform
    public var gitlabHost: String
    public var githubHost: String
    public var orgOrGroup: String
    public var authMethod: AuthMethod
    public var personalAccessToken: String
    public var refreshIntervalMinutes: Int
    public var maxInactiveDays: Int
    public var teamMembers: [TeamMember]
    public var notifyOnBlocked: Bool
    public var notifyOnReadyReview: Bool

    enum CodingKeys: String, CodingKey {
        case platform
        case gitlabHost
        case githubHost
        case orgOrGroup
        case groupId // legacy backward compatibility
        case authMethod
        case personalAccessToken
        case refreshIntervalMinutes
        case maxInactiveDays
        case teamMembers
        case notifyOnBlocked
        case notifyOnReadyReview
    }

    public init(
        platform: GitPlatform = .gitlab,
        gitlabHost: String = "gitlab.com",
        githubHost: String = "github.com",
        orgOrGroup: String = "",
        authMethod: AuthMethod = .cli,
        personalAccessToken: String = "",
        refreshIntervalMinutes: Int = 3,
        maxInactiveDays: Int = 45,
        teamMembers: [TeamMember] = [],
        notifyOnBlocked: Bool = true,
        notifyOnReadyReview: Bool = true
    ) {
        self.platform = platform
        self.gitlabHost = gitlabHost
        self.githubHost = githubHost
        self.orgOrGroup = orgOrGroup
        self.authMethod = authMethod
        self.personalAccessToken = personalAccessToken
        self.refreshIntervalMinutes = refreshIntervalMinutes
        self.maxInactiveDays = maxInactiveDays
        self.teamMembers = teamMembers
        self.notifyOnBlocked = notifyOnBlocked
        self.notifyOnReadyReview = notifyOnReadyReview
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.platform = try container.decodeIfPresent(GitPlatform.self, forKey: .platform) ?? .gitlab
        self.gitlabHost = try container.decodeIfPresent(String.self, forKey: .gitlabHost) ?? "gitlab.com"
        self.githubHost = try container.decodeIfPresent(String.self, forKey: .githubHost) ?? "github.com"
        
        // Handle both new orgOrGroup and legacy groupId
        if let org = try container.decodeIfPresent(String.self, forKey: .orgOrGroup) {
            self.orgOrGroup = org
        } else if let legacyGroup = try container.decodeIfPresent(String.self, forKey: .groupId) {
            self.orgOrGroup = legacyGroup
        } else {
            self.orgOrGroup = ""
        }

        self.authMethod = try container.decodeIfPresent(AuthMethod.self, forKey: .authMethod) ?? .cli
        self.personalAccessToken = try container.decodeIfPresent(String.self, forKey: .personalAccessToken) ?? ""
        self.refreshIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .refreshIntervalMinutes) ?? 3
        self.maxInactiveDays = try container.decodeIfPresent(Int.self, forKey: .maxInactiveDays) ?? 45
        self.teamMembers = try container.decodeIfPresent([TeamMember].self, forKey: .teamMembers) ?? AppConfig.default.teamMembers
        self.notifyOnBlocked = try container.decodeIfPresent(Bool.self, forKey: .notifyOnBlocked) ?? true
        self.notifyOnReadyReview = try container.decodeIfPresent(Bool.self, forKey: .notifyOnReadyReview) ?? true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(platform, forKey: .platform)
        try container.encode(gitlabHost, forKey: .gitlabHost)
        try container.encode(githubHost, forKey: .githubHost)
        try container.encode(orgOrGroup, forKey: .orgOrGroup)
        try container.encode(orgOrGroup, forKey: .groupId) // also write groupId for backward compatibility
        try container.encode(authMethod, forKey: .authMethod)
        try container.encode(personalAccessToken, forKey: .personalAccessToken)
        try container.encode(refreshIntervalMinutes, forKey: .refreshIntervalMinutes)
        try container.encode(maxInactiveDays, forKey: .maxInactiveDays)
        try container.encode(teamMembers, forKey: .teamMembers)
        try container.encode(notifyOnBlocked, forKey: .notifyOnBlocked)
        try container.encode(notifyOnReadyReview, forKey: .notifyOnReadyReview)
    }

    public static let `default` = AppConfig(
        platform: .gitlab,
        gitlabHost: "gitlab.com",
        githubHost: "github.com",
        orgOrGroup: "",
        authMethod: .cli,
        personalAccessToken: "",
        refreshIntervalMinutes: 3,
        maxInactiveDays: 45,
        teamMembers: [
            TeamMember(username: "alice", displayName: "Alice"),
            TeamMember(username: "bob", displayName: "Bob"),
            TeamMember(username: "charlie", displayName: "Charlie")
        ],
        notifyOnBlocked: true,
        notifyOnReadyReview: true
    )
}
