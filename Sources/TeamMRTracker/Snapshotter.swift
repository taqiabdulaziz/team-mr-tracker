import SwiftUI
import AppKit

@MainActor
public struct Snapshotter {
    public static func capture(to outputPath: String) {
        let vm = MRTrackerViewModel()

        // Configure anonymized showcase team for the public screenshot
        vm.config.teamMembers = [
            TeamMember(username: "alex.dev", displayName: "Alex"),
            TeamMember(username: "sam.k", displayName: "Sam"),
            TeamMember(username: "jordan.m", displayName: "Jordan"),
            TeamMember(username: "taylor.w", displayName: "Taylor"),
            TeamMember(username: "morgan.b", displayName: "Morgan"),
            TeamMember(username: "casey.r", displayName: "Casey")
        ]
        vm.mergeRequests = createSampleShowcaseItems()

        let view = ContentView(viewModel: vm)
            .preferredColorScheme(.dark)
            .frame(width: 480, height: 620)

        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 480, height: 620)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 620),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor.windowBackgroundColor
        window.contentView = hosting
        window.layoutIfNeeded()
        hosting.layoutSubtreeIfNeeded()

        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            print("Failed to initialize bitmap rep")
            return
        }

        hosting.cacheDisplay(in: hosting.bounds, to: rep)

        if let pngData = rep.representation(using: .png, properties: [:]) {
            let url = URL(fileURLWithPath: outputPath)
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            do {
                try pngData.write(to: url)
                print("✓ Successfully generated anonymized screenshot at \(outputPath) (\(pngData.count) bytes)")
            } catch {
                print("Failed to save screenshot: \(error)")
            }
        }
    }

    private static func createSampleShowcaseItems() -> [MergeRequestItem] {
        let sample1 = GitLabMRResponse(
            id: 101,
            iid: 78,
            project_id: 1,
            title: "feat(auth): add OAuth2 PKCE flow for mobile clients",
            description: nil,
            state: "opened",
            created_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-14400)),
            updated_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200)),
            target_branch: "main",
            source_branch: "feat/oauth2-pkce-flow",
            user_notes_count: 3,
            upvotes: 0,
            downvotes: 0,
            author: GitLabAuthor(id: 1, username: "alex.dev", name: "Alex Chen", avatar_url: nil),
            reviewers: [GitLabReviewer(id: 2, username: "sam.k", name: "Sam", avatar_url: nil)],
            draft: false,
            work_in_progress: false,
            merge_status: "cannot_be_merged",
            detailed_merge_status: "need_rebase",
            references: GitLabReferences(short: "!78", relative: "core/payment-gateway!78", full: "core/payment-gateway!78"),
            web_url: "https://gitlab.com",
            has_conflicts: false,
            blocking_discussions_resolved: false,
            task_completion_status: GitLabTaskStatus(count: 3, completed_count: 3)
        )

        let sample2 = GitLabMRResponse(
            id: 102,
            iid: 40,
            project_id: 2,
            title: "refactor(events): migrate notification worker to Spring Boot 3.3.4",
            description: nil,
            state: "opened",
            created_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)),
            updated_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-18000)),
            target_branch: "main",
            source_branch: "refactor/spring-boot-upgrade",
            user_notes_count: 1,
            upvotes: 1,
            downvotes: 0,
            author: GitLabAuthor(id: 2, username: "sam.k", name: "Sam Taylor", avatar_url: nil),
            reviewers: [
                GitLabReviewer(id: 1, username: "alex.dev", name: "Alex", avatar_url: nil),
                GitLabReviewer(id: 4, username: "taylor.w", name: "Taylor", avatar_url: nil)
            ],
            draft: false,
            work_in_progress: false,
            merge_status: "can_be_merged",
            detailed_merge_status: "not_approved",
            references: GitLabReferences(short: "!40", relative: "services/notification-service!40", full: "services/notification-service!40"),
            web_url: "https://gitlab.com",
            has_conflicts: false,
            blocking_discussions_resolved: true,
            task_completion_status: GitLabTaskStatus(count: 4, completed_count: 4)
        )

        let sample3 = GitLabMRResponse(
            id: 103,
            iid: 338,
            project_id: 3,
            title: "fix(billing): handle currency rounding precision on invoices",
            description: nil,
            state: "opened",
            created_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-259200)),
            updated_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
            target_branch: "main",
            source_branch: "fix/invoice-rounding",
            user_notes_count: 0,
            upvotes: 2,
            downvotes: 0,
            author: GitLabAuthor(id: 3, username: "jordan.m", name: "Jordan Miller", avatar_url: nil),
            reviewers: [GitLabReviewer(id: 1, username: "alex.dev", name: "Alex", avatar_url: nil)],
            draft: false,
            work_in_progress: false,
            merge_status: "can_be_merged",
            detailed_merge_status: "mergeable",
            references: GitLabReferences(short: "!338", relative: "backend/auth-service!338", full: "backend/auth-service!338"),
            web_url: "https://gitlab.com",
            has_conflicts: false,
            blocking_discussions_resolved: true,
            task_completion_status: nil
        )

        return [MergeRequestItem(from: sample1), MergeRequestItem(from: sample2), MergeRequestItem(from: sample3)]
    }
}
