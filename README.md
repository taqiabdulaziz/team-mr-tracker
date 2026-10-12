# Team PR & MR Tracker (macOS)

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-black?logo=apple&logoColor=white)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift&logoColor=white)](https://swift.org)
[![GitLab](https://img.shields.io/badge/GitLab-Supported-fc6d26?logo=gitlab&logoColor=white)](https://gitlab.com)
[![GitHub](https://img.shields.io/badge/GitHub-Supported-181717?logo=github&logoColor=white)](https://github.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A native, lightweight macOS menu bar utility (~1.2 MB binary, <25 MB RAM) designed for engineering leads and managers to track, triage, and unblock their team's Pull Requests and Merge Requests across **hundreds of microservices** in real time.

---

## 💡 The Problem & The Solution

- **The Microservice Bottleneck**: Teams often own 20 to 100+ separate repositories. Web UIs are either scoped to single repos or buried in notification noise.
- **Sub-Second Global Aggregation**: Instead of crawling repos sequentially, Team PR & MR Tracker uses native cross-repo aggregation endpoints (`/groups/:id/merge_requests` on GitLab, `/search/issues` on GitHub) to fetch all active PRs across every repo in **< 1 second**.
- **Ready Out of the Box**: Portable across machines. Supports both **GitLab** and **GitHub**, authenticates via your existing CLI tools (`gh` or `glab`) or direct Personal Access Tokens (PAT).

---

## ✨ Features

- 🦊 / 🐙 **Dual-Platform (GitLab & GitHub)**: Seamlessly switch between GitLab and GitHub with 1-click in Preferences. Supports `gitlab.com`, `github.com`, GitHub Enterprise, and self-hosted GitLab instances.
- 💻 **Zero-Login CLI Integration**: Automatically uses your existing `gh` or `glab` authentication from the macOS keychain. Alternatively, accepts a direct Personal Access Token (PAT).
- 👥 **Team Member Filter Chips**: Filter the entire dashboard by teammate with a single click. Teammates with blocked PRs show a red alert badge.
- 🚦 **Action-Oriented Triage Matrix**:
  - 🔴 **Blocked**: Merge conflicts, broken CI pipelines, needs rebase, or unresolved review threads.
  - 🟡 **Needs Review**: Ready for review and awaiting approvals.
  - 🟢 **Merge Ready**: All approvals met and pipeline is green.
  - ⚪ **Drafts**: Work in progress.
- ⏱ **Inactivity & Staleness Control**:
  - Automatically excludes stagnant PRs with no activity for more than 45 days (customizable: 14, 30, 45, 60, 90 days).
  - Highlights PRs untouched for `> 48 hours`.
- ⚡ **1-Click Developer Actions**:
  - `Open PR/MR` in browser
  - `Copy Branch` to clipboard
  - `Copy Checkout`: Copies `gh pr checkout <id> -R <repo>` or `glab mr checkout <id> -R <repo>`
- ⚙️ **In-App Preferences GUI**: Add, edit, or remove teammates, switch platforms, set polling intervals (1m, 3m, 5m), and test API connections live.

---

## 🚀 Quick Start

### Option 1: Run directly with Swift
```bash
git clone https://github.com/taqiabdulaziz/team-mr-tracker.git
cd team-mr-tracker
swift run
```

### Option 2: Build the standalone macOS `.app` bundle
```bash
./build_app.sh
open TeamMRTracker.app
```

To install into `/Applications`:
```bash
cp -R TeamMRTracker.app /Applications/
```

---

## ⚙️ Configuration

You can configure everything inside the app by clicking the **gear icon (⚙)** in the header.

Preferences are saved locally to `~/.config/team-mr-tracker/config.json`:

```json
{
  "platform": "GitLab",
  "authMethod": "CLI Tool",
  "personalAccessToken": "",
  "gitlabHost": "gitlab.com",
  "githubHost": "github.com",
  "orgOrGroup": "my-org-or-group",
  "refreshIntervalMinutes": 3,
  "maxInactiveDays": 45,
  "teamMembers": [
    { "displayName": "Alice", "username": "alice" },
    { "displayName": "Bob", "username": "bob" },
    { "displayName": "Charlie", "username": "charlie" }
  ],
  "notifyOnBlocked": true,
  "notifyOnReadyReview": true
}
```

### Notes on Configuration Fields:
- **`platform`**: `"GitLab"` or `"GitHub"`.
- **`authMethod`**: `"CLI Tool"` (uses `glab` or `gh` CLI) or `"Personal Access Token"`.
- **`orgOrGroup`**: Scopes queries to a specific GitLab group or GitHub organization. Leave empty to query across all repositories accessible to your account.
- **`maxInactiveDays`**: Automatically filters out stale PRs untouched for longer than this threshold (default: 45 days).

---

## 🛠 Tech Stack & Architecture

- **Language**: Swift 6 (Strict Concurrency safe, `@Sendable` compliant)
- **Framework**: SwiftUI (`MenuBarExtra(.window)` with `NSApplication.shared.setActivationPolicy(.accessory)`)
- **Package Manager**: Swift Package Manager (no Xcode project required)
- **Footprint**: ~1.2 MB compiled executable, <25 MB memory usage, 0% CPU idle

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
