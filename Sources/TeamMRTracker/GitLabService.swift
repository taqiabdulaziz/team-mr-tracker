import Foundation

public actor GitLabService {
    public static let shared = GitLabService()

    private var glabBinaryPath: String?

    public init() {
        self.glabBinaryPath = Self.findGlabBinary()
    }

    private static func findGlabBinary() -> String? {
        let candidates = [
            "/opt/homebrew/bin/glab",
            "/usr/local/bin/glab",
            "/usr/bin/glab",
            "/opt/local/bin/glab"
        ]
        let fm = FileManager.default
        for path in candidates {
            if fm.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    public func verifyGlabAvailable() -> (available: Bool, path: String?, error: String?) {
        if let path = glabBinaryPath {
            return (true, path, nil)
        }
        return (false, nil, "glab CLI not found in /opt/homebrew/bin or /usr/local/bin.")
    }

    public func fetchMRsForMember(
        username: String,
        groupId: String,
        host: String = "gitlab.com",
        authMethod: AuthMethod = .cli,
        token: String = "",
        maxInactiveDays: Int = 45
    ) async throws -> [MergeRequestItem] {
        let endpoint: String
        let trimmedGroup = groupId.trimmingCharacters(in: .whitespacesAndNewlines)

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -max(1, maxInactiveDays), to: Date()) ?? Date()
        let isoFormatter = ISO8601DateFormatter()
        let updatedAfter = isoFormatter.string(from: cutoffDate)

        if !trimmedGroup.isEmpty {
            let encodedGroup = trimmedGroup.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmedGroup
            endpoint = "groups/\(encodedGroup)/merge_requests?state=opened&author_username=\(username)&updated_after=\(updatedAfter)&per_page=50"
        } else {
            endpoint = "merge_requests?scope=all&state=opened&author_username=\(username)&updated_after=\(updatedAfter)&per_page=50"
        }

        let outputData: Data
        if authMethod == .token, !token.trimmingCharacters(in: .whitespaces).isEmpty {
            let cleanHost = host.trimmingCharacters(in: .whitespaces).isEmpty ? "gitlab.com" : host
            guard let url = URL(string: "https://\(cleanHost)/api/v4/\(endpoint)") else {
                throw NSError(domain: "GitLabService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid GitLab URL"])
            }
            var request = URLRequest(url: url)
            request.setValue(token.trimmingCharacters(in: .whitespaces), forHTTPHeaderField: "PRIVATE-TOKEN")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("TeamMRTracker-macOS", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 400 {
                let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpRes.statusCode)"
                throw NSError(domain: "GitLabService", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            outputData = data
        } else {
            guard let glabPath = glabBinaryPath ?? Self.findGlabBinary() else {
                throw NSError(domain: "GitLabService", code: 1, userInfo: [NSLocalizedDescriptionKey: "glab CLI not found"])
            }
            outputData = try await runProcess(executable: glabPath, arguments: ["api", endpoint])
        }

        let decoder = JSONDecoder()
        let rawItems = try decoder.decode([GitLabMRResponse].self, from: outputData)
        let items = rawItems.map { MergeRequestItem(from: $0) }
        return items.filter { $0.daysSinceUpdate <= maxInactiveDays }
    }

    public func fetchTeamMRs(
        members: [TeamMember],
        groupId: String,
        host: String = "gitlab.com",
        authMethod: AuthMethod = .cli,
        token: String = "",
        maxInactiveDays: Int = 45
    ) async throws -> [MergeRequestItem] {
        return try await withThrowingTaskGroup(of: (String, Result<[MergeRequestItem], Error>).self) { group in
            for member in members {
                group.addTask {
                    do {
                        let items = try await self.fetchMRsForMember(
                            username: member.username,
                            groupId: groupId,
                            host: host,
                            authMethod: authMethod,
                            token: token,
                            maxInactiveDays: maxInactiveDays
                        )
                        return (member.username, .success(items))
                    } catch {
                        return (member.username, .failure(error))
                    }
                }
            }

            var allMRs: [MergeRequestItem] = []
            var lastError: Error?

            for try await (_, result) in group {
                switch result {
                case .success(let items):
                    allMRs.append(contentsOf: items)
                case .failure(let err):
                    lastError = err
                }
            }

            if allMRs.isEmpty, let err = lastError {
                let errStr = err.localizedDescription
                if errStr.contains("invalid_grant") || errStr.contains("401") || errStr.contains("Unauthorized") {
                    throw NSError(
                        domain: "GitLabService",
                        code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "GitLab session expired (OAuth invalid_grant). Please run 'glab auth login' in terminal or enter a Personal Access Token in app Settings."]
                    )
                }
                throw err
            }

            var seen = Set<Int>()
            var unique: [MergeRequestItem] = []
            for mr in allMRs {
                if !seen.contains(mr.id) {
                    seen.insert(mr.id)
                    unique.append(mr)
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
                            domain: "GitLabService",
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
