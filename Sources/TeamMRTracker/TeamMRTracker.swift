import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

@main
struct TeamMRTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = MRTrackerViewModel()

    init() {
        if CommandLine.arguments.contains("--snapshot") {
            let outputIndex = CommandLine.arguments.firstIndex(of: "--snapshot").flatMap { $0 + 1 }
            let outputPath = (outputIndex != nil && outputIndex! < CommandLine.arguments.count)
                ? CommandLine.arguments[outputIndex!]
                : "assets/screenshot.png"
            Snapshotter.capture(to: outputPath)
            exit(0)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "arrow.triangle.pull")
                if viewModel.attentionCount > 0 {
                    Text("\(viewModel.attentionCount)")
                        .font(.system(size: 11, weight: .bold))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
