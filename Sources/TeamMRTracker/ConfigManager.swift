import Foundation

@MainActor
public final class ConfigManager {
    public static let shared = ConfigManager()

    private let fileManager = FileManager.default
    private var configURL: URL {
        let home = fileManager.homeDirectoryForCurrentUser
        let dir = home.appendingPathComponent(".config/team-mr-tracker", isDirectory: true)
        return dir.appendingPathComponent("config.json")
    }

    private init() {}

    public func loadConfig() -> AppConfig {
        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            return try decoder.decode(AppConfig.self, from: data)
        } catch {
            let defaultConfig = AppConfig.default
            saveConfig(defaultConfig)
            return defaultConfig
        }
    }

    public func saveConfig(_ config: AppConfig) {
        do {
            let dir = configURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: dir.path) {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configURL, options: .atomic)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
