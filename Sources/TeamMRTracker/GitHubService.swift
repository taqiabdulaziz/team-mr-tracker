import Foundation

public actor GitHubService {
    public static let shared = GitHubService()

    private var ghBinaryPath: String?

    public init() {
        self.ghBinaryPath = Self.findGhBinary()
    }

    private static func findGhBinary() -> String? {
        let candidates = [
            "/opt/homebrew/bin/gh",
            "/usr/local/bin/gh",
            "/usr/bin/gh",
            "/opt/local/bin/gh"
        ]
        let fm = FileManager.default
        for path in candidates {
            if fm.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    public func verifyGhAvailable() -> (available: Bool, path: String?, error: String?) {
        if let path = ghBinaryPath {
            return (true, path, nil)
        }
        return (false, nil, "gh CLI not found in /opt/homebrew/bin or /usr/local/bin.")
    }

    public func fetchPRsForMember(
        username: String,
        org: String,
        host: String,
        authMethod: AuthMethod,
        token: String,
        maxInactiveDays: Int
    ) async throws -> [MergeRequestItem] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -max(1, maxInactiveDays), to: Date()) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let updatedDate = dateFormatter.string(from: cutoffDate)

        var queryParts = ["is:pr", "is:open", "author:\(username)", "updated:>=\(updatedDate)"]
        let trimmedOrg = org.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedOrg.isEmpty {
            queryParts.append("org:\(trimmedOrg)")
        }

        let rawQuery = queryParts.joined(separator: " ")
        let encodedQuery = rawQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? rawQuery

        let outputData: Data
        if authMethod == .token, !token.trimmingCharacters(in: .whitespaces).isEmpty {
            // Direct REST via URLSession
            let baseURL = host.contains("github.com") ? "https://api.github.com" : "https://\(host)/api/v3"
            guard let url = URL(string: "\(baseURL)/search/issues?q=\(encodedQuery)&per_page=50") else {
                throw NSError(domain: "GitHubService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid GitHub URL"])
            }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token.trimmingCharacters(in: .whitespaces))", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("TeamMRTracker-macOS", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 400 {
                let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpRes.statusCode)"
                throw NSError(domain: "GitHubService", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            outputData = data
        } else {
            // CLI mode via gh
            guard let ghPath = ghBinaryPath ?? Self.findGhBinary() else {
                throw NSError(domain: "GitHubService", code: 1, userInfo: [NSLocalizedDescriptionKey: "gh CLI not found"])
            }
            let endpoint = "search/issues?q=\(encodedQuery)&per_page=50"
            outputData = try await runProcess(executable: ghPath, arguments: ["api", endpoint])
        }

        let decoder = JSONDecoder()
        let searchResult = try decoder.decode(GitHubSearchResponse.self, from: outputData)
        let items = searchResult.items.map { MergeRequestItem(from: $0) }
        return items.filter { $0.daysSinceUpdate <= maxInactiveDays }
    }

    public func fetchTeamPRs(
        members: [TeamMember],
        org: String,
        host: String,
        authMethod: AuthMethod,
        token: String,
        maxInactiveDays: Int
    ) async -> [MergeRequestItem] {
        await withTaskGroup(of: [MergeRequestItem].self) { group in
            for member in members {
                group.addTask {
                    do {
                        return try await self.fetchPRsForMember(
                            username: member.username,
                            org: org,
                            host: host,
                            authMethod: authMethod,
                            token: token,
                            maxInactiveDays: maxInactiveDays
                        )
                    } catch {
                        print("Error fetching GitHub PRs for \(member.username): \(error)")
                        return []
                    }
                }
            }

            var allPRs: [MergeRequestItem] = []
            for await memberPRs in group {
                allPRs.append(contentsOf: memberPRs)
            }

            var seen = Set<Int>()
            var unique: [MergeRequestItem] = []
            for pr in allPRs {
                if !seen.contains(pr.id) {
                    seen.insert(pr.id)
                    unique.append(pr)
                }
            }

            return unique.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    private func runProcess(executable: String, arguments: [String]) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments

                var env = ProcessInfo.processInfo.environment
                let currentPath = env["PATH"] ?? ""
                env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:\(currentPath)"
                process.environment = env

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                    let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: data)
                    } else {
                        let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                        let errString = String(data: errData, encoding: .utf8) ?? "Unknown process error"
                        continuation.resume(throwing: NSError(
                            domain: "GitHubService",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: errString]
                        ))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
