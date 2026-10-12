import Foundation

public actor GitProviderService {
    public static let shared = GitProviderService()

    private init() {}

    public func fetchTeamItems(config: AppConfig) async -> [MergeRequestItem] {
        switch config.platform {
        case .gitlab:
            return await GitLabService.shared.fetchTeamMRs(
                members: config.teamMembers,
                groupId: config.orgOrGroup,
                host: config.gitlabHost,
                authMethod: config.authMethod,
                token: config.personalAccessToken,
                maxInactiveDays: config.maxInactiveDays
            )
        case .github:
            return await GitHubService.shared.fetchTeamPRs(
                members: config.teamMembers,
                org: config.orgOrGroup,
                host: config.githubHost,
                authMethod: config.authMethod,
                token: config.personalAccessToken,
                maxInactiveDays: config.maxInactiveDays
            )
        }
    }

    public func verifyConnection(config: AppConfig) async -> (available: Bool, message: String) {
        switch config.platform {
        case .gitlab:
            if config.authMethod == .token {
                if config.personalAccessToken.trimmingCharacters(in: .whitespaces).isEmpty {
                    return (false, "Please provide a GitLab Personal Access Token.")
                }
                // Quick REST call to test token
                let host = config.gitlabHost.trimmingCharacters(in: .whitespaces).isEmpty ? "gitlab.com" : config.gitlabHost
                guard let url = URL(string: "https://\(host)/api/v4/user") else {
                    return (false, "Invalid GitLab host URL.")
                }
                var req = URLRequest(url: url)
                req.setValue(config.personalAccessToken.trimmingCharacters(in: .whitespaces), forHTTPHeaderField: "PRIVATE-TOKEN")
                do {
                    let (data, res) = try await URLSession.shared.data(for: req)
                    if let http = res as? HTTPURLResponse, http.statusCode == 200 {
                        if let user = try? JSONDecoder().decode(GitLabAuthor.self, from: data) {
                            return (true, "✓ Connected to GitLab as @\(user.username)")
                        }
                        return (true, "✓ Connected to GitLab successfully")
                    } else {
                        return (false, "✗ GitLab authentication failed (HTTP \((res as? HTTPURLResponse)?.statusCode ?? 400))")
                    }
                } catch {
                    return (false, "✗ GitLab connection error: \(error.localizedDescription)")
                }
            } else {
                let check = await GitLabService.shared.verifyGlabAvailable()
                if check.available {
                    return (true, "✓ glab CLI available at \(check.path ?? "PATH")")
                } else {
                    return (false, "✗ \(check.error ?? "glab CLI not found")")
                }
            }

        case .github:
            if config.authMethod == .token {
                if config.personalAccessToken.trimmingCharacters(in: .whitespaces).isEmpty {
                    return (false, "Please provide a GitHub Personal Access Token.")
                }
                let host = config.githubHost.trimmingCharacters(in: .whitespaces).isEmpty ? "api.github.com" : config.githubHost
                let baseURL = host.contains("github.com") ? "https://api.github.com" : "https://\(host)/api/v3"
                guard let url = URL(string: "\(baseURL)/user") else {
                    return (false, "Invalid GitHub host URL.")
                }
                var req = URLRequest(url: url)
                req.setValue("Bearer \(config.personalAccessToken.trimmingCharacters(in: .whitespaces))", forHTTPHeaderField: "Authorization")
                req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                req.setValue("TeamMRTracker-macOS", forHTTPHeaderField: "User-Agent")
                do {
                    let (data, res) = try await URLSession.shared.data(for: req)
                    if let http = res as? HTTPURLResponse, http.statusCode == 200 {
                        if let user = try? JSONDecoder().decode(GitHubUser.self, from: data) {
                            return (true, "✓ Connected to GitHub as @\(user.login)")
                        }
                        return (true, "✓ Connected to GitHub successfully")
                    } else {
                        return (false, "✗ GitHub authentication failed (HTTP \((res as? HTTPURLResponse)?.statusCode ?? 400))")
                    }
                } catch {
                    return (false, "✗ GitHub connection error: \(error.localizedDescription)")
                }
            } else {
                let check = await GitHubService.shared.verifyGhAvailable()
                if check.available {
                    return (true, "✓ gh CLI available at \(check.path ?? "PATH")")
                } else {
                    return (false, "✗ \(check.error ?? "gh CLI not found")")
                }
            }
        }
    }
}
