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
