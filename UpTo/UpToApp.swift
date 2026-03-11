import SwiftUI

@main
struct UpToApp: App {
    @State private var monitor = StatusMonitor()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            StatusPopoverView(monitor: monitor)
        } label: {
            Image(nsImage: MenuBarIcon.statusImage(for: monitor.overallStatus))
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock and app switcher
        NSApp.setActivationPolicy(.accessory)
    }
}
