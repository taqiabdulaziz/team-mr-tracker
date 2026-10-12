import SwiftUI

public struct SettingsView: View {
    @ObservedObject var viewModel: MRTrackerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var platform: GitPlatform = .gitlab
    @State private var authMethod: AuthMethod = .cli
    @State private var personalAccessToken: String = ""
    @State private var host: String = ""
    @State private var orgOrGroup: String = ""
    @State private var refreshInterval: Int = 3
    @State private var maxInactiveDays: Int = 45
    @State private var teamMembers: [TeamMember] = []

    // New member input
    @State private var newUsername: String = ""
    @State private var newDisplayName: String = ""

    // Diagnostics
    @State private var connectionStatus: String? = nil
    @State private var isTesting: Bool = false

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings & Preferences")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button("Save & Close") {
                    saveAndDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Platform & Authentication
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Git Platform")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        Picker("Platform", selection: $platform) {
                            Text("GitLab").tag(GitPlatform.gitlab)
                            Text("GitHub").tag(GitPlatform.github)
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            Text("Authentication:")
                                .font(.system(size: 11))
                                .frame(width: 140, alignment: .leading)
                            Picker("", selection: $authMethod) {
                                Text("CLI Tool (\(platform.cliToolName))").tag(AuthMethod.cli)
                                Text("Access Token (PAT)").tag(AuthMethod.token)
                            }
                            .pickerStyle(.menu)
                        }

                        if authMethod == .token {
                            HStack {
                                Text("Personal Token:")
                                    .font(.system(size: 11))
                                    .frame(width: 140, alignment: .leading)
                                SecureField("ghp_... or glpat-...", text: $personalAccessToken)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11))
                            }
                        }

                        HStack {
                            Text("\(platform.groupLabel):")
                                .font(.system(size: 11))
                                .frame(width: 140, alignment: .leading)
                            TextField(platform == .gitlab ? "e.g. my-group (blank for all)" : "e.g. my-org (blank for all)", text: $orgOrGroup)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }

                        HStack {
                            Text("Server Host:")
                                .font(.system(size: 11))
                                .frame(width: 140, alignment: .leading)
                            TextField(platform == .gitlab ? "gitlab.com" : "github.com", text: $host)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }
                    }

                    Divider()

                    // Polling & Filtering
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sync & Filters")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack {
                            Text("Auto-refresh interval:")
                                .font(.system(size: 11))
                                .frame(width: 140, alignment: .leading)
                            Picker("", selection: $refreshInterval) {
                                Text("Every 1 minute").tag(1)
                                Text("Every 3 minutes").tag(3)
                                Text("Every 5 minutes").tag(5)
                                Text("Every 15 minutes").tag(15)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 160)
                        }

                        HStack {
                            Text("Exclude inactive \(platform.term)s:")
                                .font(.system(size: 11))
                                .frame(width: 140, alignment: .leading)
                            Picker("", selection: $maxInactiveDays) {
                                Text("Older than 14 days").tag(14)
                                Text("Older than 30 days").tag(30)
                                Text("Older than 45 days").tag(45)
                                Text("Older than 60 days").tag(60)
                                Text("Older than 90 days").tag(90)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 160)
                        }
                    }

                    Divider()

                    // Team Members Manager
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Team Members (\(teamMembers.count))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Monitored across repositories")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        // List of members
                        VStack(spacing: 5) {
                            ForEach(teamMembers) { member in
                                HStack {
                                    Image(systemName: "person.circle")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 12))
                                    Text(member.displayName)
                                        .font(.system(size: 11, weight: .medium))
                                    Text("(@\(member.username))")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(action: {
                                        deleteMember(member)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 10))
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Remove \(member.displayName)")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                        }

                        // Add new member form
                        HStack(spacing: 6) {
                            TextField("Username (e.g. octocat)", text: $newUsername)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))

                            TextField("Display Name (e.g. Mona)", text: $newDisplayName)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))

                            Button(action: addMember) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .disabled(newUsername.trimmingCharacters(in: .whitespaces).isEmpty)
                            .help("Add Team Member")
                        }
                        .padding(.top, 4)
                    }

                    Divider()

                    // Connection Test
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Connection Diagnostics")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack {
                            Button("Test Connection") {
                                testConnection()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(isTesting)

                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }

                            if let status = connectionStatus {
                                Text(status)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(status.contains("✓") ? .green : .red)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 460, height: 530)
        .onAppear {
            self.platform = viewModel.config.platform
            self.authMethod = viewModel.config.authMethod
            self.personalAccessToken = viewModel.config.personalAccessToken
            self.host = (viewModel.config.platform == .gitlab) ? viewModel.config.gitlabHost : viewModel.config.githubHost
            self.orgOrGroup = viewModel.config.orgOrGroup
            self.refreshInterval = viewModel.config.refreshIntervalMinutes
            self.maxInactiveDays = viewModel.config.maxInactiveDays
            self.teamMembers = viewModel.config.teamMembers
        }
    }

    private func addMember() {
        let username = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { return }
        let display = newDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? username : newDisplayName
        teamMembers.append(TeamMember(username: username, displayName: display))
        newUsername = ""
        newDisplayName = ""
    }

    private func deleteMember(_ member: TeamMember) {
        teamMembers.removeAll { $0.username == member.username }
    }

    private func testConnection() {
        isTesting = true
        connectionStatus = nil
        Task {
            var temp = viewModel.config
            temp.platform = platform
            temp.authMethod = authMethod
            temp.personalAccessToken = personalAccessToken
            if platform == .gitlab {
                temp.gitlabHost = host.isEmpty ? "gitlab.com" : host
            } else {
                temp.githubHost = host.isEmpty ? "github.com" : host
            }
            temp.orgOrGroup = orgOrGroup

            let res = await GitProviderService.shared.verifyConnection(config: temp)
            self.connectionStatus = res.message
            self.isTesting = false
        }
    }

    private func saveAndDismiss() {
        var updated = viewModel.config
        updated.platform = platform
        updated.authMethod = authMethod
        updated.personalAccessToken = personalAccessToken
        if platform == .gitlab {
            updated.gitlabHost = host.isEmpty ? "gitlab.com" : host
        } else {
            updated.githubHost = host.isEmpty ? "github.com" : host
        }
        updated.orgOrGroup = orgOrGroup.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.refreshIntervalMinutes = refreshInterval
        updated.maxInactiveDays = maxInactiveDays
        updated.teamMembers = teamMembers
        viewModel.updateConfig(updated)
        viewModel.showSettings = false
    }
}
